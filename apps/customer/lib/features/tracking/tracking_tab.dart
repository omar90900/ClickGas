import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/location_service.dart';
import '../../data/models/models.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../state/my_orders_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/map_icons.dart';
import '../orders/order_widgets.dart';
import '../shell/main_shell.dart';
import 'wallet_payment_card.dart';

/// Live status of the customer's open order (Supabase Realtime), or a clear
/// empty state when there is none.
class TrackingTab extends StatelessWidget {
  const TrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final orders = context.watch<MyOrdersController>();
    final open = orders.openOrder;

    final Widget body;
    if (orders.loading) {
      body = const LoadingView();
    } else if (orders.error != null) {
      body = ErrorView(onRetry: orders.retry);
    } else if (open == null && orders.awaitingConfirmation != null) {
      body = ConfirmReceiptView(order: orders.awaitingConfirmation!);
    } else if (open == null) {
      body = EmptyState(
        icon: Icons.map_outlined,
        title: l.noActiveOrderTitle,
        message: l.noActiveOrderBody,
        action: FilledButton.icon(
          onPressed: () => context.read<ShellTabs>().go(ShellTabs.home),
          icon: const Icon(Icons.propane_tank_rounded),
          label: Text(l.orderGasCta),
        ),
      );
    } else {
      body = _OpenOrderView(key: ValueKey(open.id), order: open);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.tabTracking)),
      body: body,
    );
  }
}

class _OpenOrderView extends StatefulWidget {
  const _OpenOrderView({super.key, required this.order});
  final GasOrder order;

  @override
  State<_OpenOrderView> createState() => _OpenOrderViewState();
}

class _OpenOrderViewState extends State<_OpenOrderView> {
  String? _driverId;
  Stream<DriverLocation?>? _driverLocation;
  Future<OrderDriver?>? _driverCard;
  GoogleMapController? _map;
  BitmapDescriptor? _truckIcon;
  bool _fitted = false;
  bool _cancelling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_truckIcon == null) {
      MapIcons.circle(
        Icons.local_shipping_rounded,
        background: AppColors.info,
        foreground: Colors.white,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ).then((icon) {
        if (mounted) setState(() => _truckIcon = icon);
      });
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  void _bindDriver(String? driverId) {
    if (driverId == _driverId) return;
    _driverId = driverId;
    _fitted = false;
    if (driverId == null) {
      _driverLocation = null;
      _driverCard = null;
      return;
    }
    _driverLocation = context.read<DriverRepository>().watchDriver(driverId);
    _driverCard = context.read<OrderRepository>().fetchDriver(widget.order.id);
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    if (!await confirmDialog(context, l.cancelOrderConfirm,
        confirmLabel: l.cancelOrder, destructive: true)) {
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = true);
    try {
      await context.read<OrderRepository>().cancel(widget.order.id);
      if (mounted) showSnack(context, l.orderCancelled);
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _fit(LatLng a, LatLng b) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    _map?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    _bindDriver(order.status.hasDriver ? order.driverId : null);
    return order.status == OrderStatus.pending
        ? _buildSearching(order)
        : _buildLive(order);
  }

  Widget _buildSearching(GasOrder order) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 8),
        const Center(child: _RadarPulse()),
        const SizedBox(height: 16),
        Text(
          l.searchingDriver,
          textAlign: TextAlign.center,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          l.searchingDriverBody,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _OrderHeader(order: order),
        const SizedBox(height: 16),
        OrderTimeline(order: order),
        const SizedBox(height: 16),
        OrderSummaryCard(order: order),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          onPressed: _cancelling ? null : _cancel,
          icon: const Icon(Icons.close_rounded),
          label: Text(l.cancelOrder),
        ),
      ],
    );
  }

  Widget _buildLive(GasOrder order) {
    final l = context.l10n;
    final home = LatLng(order.deliveryLat, order.deliveryLng);
    return StreamBuilder<DriverLocation?>(
      stream: _driverLocation,
      builder: (context, snap) {
        final driver = snap.data;
        final driverPos = driver == null ? null : LatLng(driver.lat, driver.lng);
        if (driverPos != null && !_fitted && _map != null) {
          _fitted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fit(home, driverPos));
        }
        final meters = driverPos == null
            ? null
            : LocationService.distanceMeters(driverPos.latitude,
                driverPos.longitude, home.latitude, home.longitude);

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: home, zoom: 15),
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: (c) => _map = c,
                    markers: {
                      Marker(
                        markerId: const MarkerId('home'),
                        position: home,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                      if (driverPos != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: driverPos,
                          anchor: const Offset(0.5, 0.5),
                          icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
                          zIndexInt: 2,
                        ),
                    },
                  ),
                  if (meters != null)
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: Chip(
                        avatar: const Icon(Icons.near_me_rounded, size: 18),
                        label: Text(l.away(Fmt.distance(context, meters))),
                      ),
                    ),
                  if (driverPos != null)
                    PositionedDirectional(
                      bottom: 12,
                      end: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'track-fit',
                        onPressed: () => _fit(home, driverPos),
                        child: const Icon(Icons.center_focus_strong_rounded),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              color: context.colors.surfaceContainerLowest,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  _OrderHeader(order: order),
                  const SizedBox(height: 16),
                  OrderTimeline(order: order),
                  const SizedBox(height: 16),
                  FutureBuilder<OrderDriver?>(
                    future: _driverCard,
                    builder: (context, s) => s.data == null
                        ? const SizedBox.shrink()
                        : _DriverCard(driver: s.data!),
                  ),
                  if (order.paymentMethod == PaymentMethod.wallet) ...[
                    const SizedBox(height: 12),
                    WalletPaymentCard(order: order),
                  ],
                  const SizedBox(height: 12),
                  OrderSummaryCard(order: order),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});
  final GasOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.orderNumber(order.orderNumber),
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        StatusChip(order.status),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final OrderDriver driver;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            UserAvatar(
              url: driver.avatarUrl,
              name: driver.fullName,
              radius: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.yourDistributor,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    driver.fullName,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      if (driver.vehiclePlate.isNotEmpty) ...[
                        Text(driver.vehiclePlate, style: context.text.bodySmall),
                        const SizedBox(width: 8),
                      ],
                      RatingStars(value: driver.ratingAvg, size: 14),
                    ],
                  ),
                ],
              ),
            ),
            if (driver.phone.isNotEmpty)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                onPressed: () =>
                    launchUrl(Uri(scheme: 'tel', path: driver.phone)),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(l.callDriver),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final phase in const [0.0, 0.5])
              Builder(builder: (context) {
                final t = (_ctrl.value + phase) % 1.0;
                return Container(
                  width: 80 + 90 * t,
                  height: 80 + 90 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand.withValues(alpha: 0.35 * (1 - t)),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: const BrandLogo(size: 80),
      ),
    );
  }
}
