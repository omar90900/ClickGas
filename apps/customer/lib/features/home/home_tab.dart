import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/location_service.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../state/my_orders_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/map_icons.dart';
import '../shell/main_shell.dart';

/// Main tab: live map of online distributors + the order form.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _amman = LatLng(31.9539, 35.9106);

  GoogleMapController? _map;
  LatLng _target = _amman;
  bool _moving = false;
  bool _located = false;
  LocationIssue? _issue;
  String? _address;
  int _geoRequest = 0;
  Timer? _geoDebounce;
  BitmapDescriptor? _truckIcon;

  late Future<(List<GasService>, AppConfig)> _catalog = _loadCatalog();
  late final Stream<List<DriverLocation>> _drivers =
      context.read<DriverRepository>().watchOnlineDrivers();

  int? _serviceId;
  int _quantity = 1;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_truckIcon == null) {
      MapIcons.circle(
        Icons.local_shipping_rounded,
        background: AppColors.brandDeep,
        foreground: Colors.white,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        size: 38,
      ).then((icon) {
        if (mounted) setState(() => _truckIcon = icon);
      });
    }
  }

  @override
  void dispose() {
    _geoDebounce?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<(List<GasService>, AppConfig)> _loadCatalog() {
    final repo = context.read<CatalogRepository>();
    return (repo.services(refresh: true), repo.config()).wait;
  }

  /// Start at the customer's city, then move to their GPS position.
  Future<void> _initCamera() async {
    final cityId = context.read<SessionController>().profile?.cityId;
    if (cityId != null) {
      try {
        final cities = await context.read<CatalogRepository>().cities();
        final city = cities.where((c) => c.id == cityId).firstOrNull;
        if (city != null && !_located) {
          _target = LatLng(city.lat, city.lng);
          await _map?.moveCamera(CameraUpdate.newLatLngZoom(_target, 13));
        }
      } catch (_) {}
    }
    await _locate();
  }

  Future<void> _locate() async {
    try {
      final p = await context.read<LocationService>().current();
      if (!mounted) return;
      final here = LatLng(p.latitude, p.longitude);
      setState(() {
        _target = here;
        _located = true;
        _issue = null;
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 16.5));
      _scheduleGeocode();
    } on LocationException catch (e) {
      if (mounted) setState(() => _issue = e.issue);
      _scheduleGeocode();
    } catch (_) {
      _scheduleGeocode();
    }
  }

  void _scheduleGeocode() {
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 450), _reverseGeocode);
  }

  /// Street name for the pin, like "ش. قاسم بن الربيع".
  Future<void> _reverseGeocode() async {
    if (kIsWeb || !mounted) return;
    final request = ++_geoRequest;
    final target = _target;
    final locale = Locale(context.lang);
    try {
      final marks = await Geocoding(locale: locale)
          .placemarkFromCoordinates(target.latitude, target.longitude);
      if (!mounted || request != _geoRequest || marks.isEmpty) return;
      final p = marks.first;
      final parts = <String>{
        for (final s in [p.street, p.thoroughfare, p.subLocality, p.locality])
          if (s != null && s.trim().isNotEmpty && !s.contains('+')) s.trim(),
      };
      setState(() => _address = parts.take(2).join('، '));
    } catch (_) {
      if (mounted && request == _geoRequest) setState(() => _address = null);
    }
  }

  Future<void> _placeOrder(GasService service, AppConfig config) async {
    final customer = context.read<SessionController>().profile;
    if (customer == null) return;
    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmOrderSheet(
        service: service,
        quantity: _quantity,
        config: config,
        address: _address,
      ),
    );
    if (notes == null || !mounted) return;

    setState(() => _placing = true);
    final l = context.l10n;
    final tabs = context.read<ShellTabs>();
    try {
      await context.read<OrderRepository>().create(
            customerId: customer.id,
            serviceId: service.id,
            quantity: _quantity,
            paymentMethod: PaymentMethod.cash,
            lat: _target.latitude,
            lng: _target.longitude,
            address: _address,
            notes: notes,
          );
      if (!mounted) return;
      showSnack(context, l.orderPlaced);
      tabs.go(ShellTabs.tracking);
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, failureText(context, f), error: true);
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final openOrder = context.watch<MyOrdersController>().openOrder;
    return Column(
      children: [
        Expanded(child: _buildMap()),
        _Panel(
          child: openOrder != null
              ? _OpenOrderCard(
                  order: openOrder,
                  onTrack: () =>
                      context.read<ShellTabs>().go(ShellTabs.tracking),
                )
              : _buildOrderForm(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final l = context.l10n;
    return Stack(
      alignment: Alignment.center,
      children: [
        StreamBuilder<List<DriverLocation>>(
          stream: _drivers,
          builder: (context, snap) {
            final drivers = snap.data ?? const <DriverLocation>[];
            return GoogleMap(
              initialCameraPosition: CameraPosition(target: _target, zoom: 13),
              myLocationEnabled: _located,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (c) {
                _map = c;
                c.moveCamera(
                  CameraUpdate.newLatLngZoom(_target, _located ? 16.5 : 13),
                );
              },
              onCameraMoveStarted: () => setState(() => _moving = true),
              onCameraMove: (p) => _target = p.target,
              onCameraIdle: () {
                setState(() => _moving = false);
                _scheduleGeocode();
              },
              markers: {
                for (final d in drivers)
                  Marker(
                    markerId: MarkerId(d.id),
                    position: LatLng(d.lat, d.lng),
                    anchor: const Offset(0.5, 0.5),
                    icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
                  ),
              },
            );
          },
        ),
        // Centre pin = delivery location; lifts while the map moves.
        IgnorePointer(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 150),
            offset: Offset(0, _moving ? -0.62 : -0.5),
            child: const Icon(
              Icons.location_on_rounded,
              size: 52,
              color: AppColors.danger,
              shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
            ),
          ),
        ),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 12,
          start: 16,
          end: 16,
          child: _issue != null
              ? _LocationIssueBar(
                  issue: _issue!,
                  onFix: () async {
                    await context
                        .read<LocationService>()
                        .openSettingsFor(_issue!);
                    await _locate();
                  },
                )
              : _AddressBar(
                  address: _address,
                  hint: _located ? l.moveMapHint : l.locating,
                ),
        ),
        PositionedDirectional(
          bottom: 16,
          end: 16,
          child: FloatingActionButton.small(
            heroTag: 'home-locate',
            tooltip: l.myLocation,
            backgroundColor: context.colors.surfaceContainerLowest,
            foregroundColor: context.accent,
            onPressed: _locate,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        PositionedDirectional(
          bottom: 20,
          start: 16,
          child: StreamBuilder<List<DriverLocation>>(
            stream: _drivers,
            builder: (context, snap) => _DistributorsChip(
              count: snap.data?.length ?? 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderForm() {
    final l = context.l10n;
    return FutureBuilder<(List<GasService>, AppConfig)>(
      future: _catalog,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _catalog = _loadCatalog()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('${l.errorGeneric}  ${l.retry}'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: LoadingView(),
          );
        }
        final (services, config) = snap.data!;
        if (services.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.servicesUnavailable, textAlign: TextAlign.center),
          );
        }
        final selected = services
                .where((s) => s.id == _serviceId)
                .firstOrNull ??
            services.first;
        // Display only - the database computes the charged total.
        final total = selected.price * _quantity + config.customerExtras;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.chooseService,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final s in services) ...[
              _ServiceCard(
                service: s,
                selected: s.id == selected.id,
                onTap: () => setState(() => _serviceId = s.id),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Text(l.quantity, style: context.text.titleSmall),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    l.quantityCount(_quantity),
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _quantity < config.maxQuantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.payments_rounded,
                    label: l.cash,
                    selected: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.credit_card_rounded,
                    label: l.card,
                    selected: false,
                    badge: l.comingSoon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _placing || _moving
                  ? null
                  : () => _placeOrder(selected, config),
              child: _placing
                  ? const ButtonSpinner()
                  : Text('${l.orderNow} · ${Fmt.money(context, total)}'),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.58,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -2)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _AddressBar extends StatelessWidget {
  const _AddressBar({required this.address, required this.hint});
  final String? address;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!.isNotEmpty;
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: context.colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.place_rounded, color: context.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.deliverTo,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hasAddress ? address! : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: hasAddress ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationIssueBar extends StatelessWidget {
  const _LocationIssueBar({required this.issue, required this.onFix});
  final LocationIssue issue;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      elevation: 3,
      color: const Color(0xFFFFF4E0),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                issue == LocationIssue.serviceDisabled
                    ? l.locationServiceDisabled
                    : l.locationPermissionDenied,
                style: context.text.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ),
            TextButton(onPressed: onFix, child: Text(l.openSettings)),
          ],
        ),
      ),
    );
  }
}

class _DistributorsChip extends StatelessWidget {
  const _DistributorsChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: context.colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.brand : context.colors.outline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.distributorsNearby(count),
              style: context.text.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final GasService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Material(
      color: selected
          ? context.colors.primaryContainer
          : context.colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppColors.brand : context.colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brand
                          : context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      serviceIcon(service.icon),
                      color: selected
                          ? AppColors.onBrand
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (service.badge != null)
                    PositionedDirectional(
                      top: -8,
                      start: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.badge!,
                          style: context.text.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name(lang),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      service.description(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.money(context, service.price),
                style: context.text.titleSmall?.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.selected,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = badge == null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer
              : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? context.accent : null),
            const SizedBox(width: 8),
            Text(
              label,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Text(
                '($badge)',
                style: context.text.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpenOrderCard extends StatelessWidget {
  const _OpenOrderCard({required this.order, required this.onTrack});
  final GasOrder order;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              order.status == OrderStatus.pending
                  ? Icons.hourglass_top_rounded
                  : Icons.local_shipping_rounded,
              color: context.accent,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.activeOrderExists,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${l.orderNumber(order.orderNumber)} · '
                    '${order.serviceName(context.lang)}',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(order.status),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onTrack,
          icon: const Icon(Icons.map_rounded),
          label: Text(l.trackIt),
        ),
      ],
    );
  }
}

/// Final check before sending: summary + optional note for the driver.
/// Pops with the note text ('' when empty) or null when dismissed.
class _ConfirmOrderSheet extends StatefulWidget {
  const _ConfirmOrderSheet({
    required this.service,
    required this.quantity,
    required this.config,
    required this.address,
  });

  final GasService service;
  final int quantity;
  final AppConfig config;
  final String? address;

  @override
  State<_ConfirmOrderSheet> createState() => _ConfirmOrderSheetState();
}

class _ConfirmOrderSheetState extends State<_ConfirmOrderSheet> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.service;
    final fee = widget.config.deliveryFee;
    final serviceFee = widget.config.fees.customerFee;
    // Display only - the database recomputes the real total on insert.
    final total = s.price * widget.quantity + fee + serviceFee;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.orderNow,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          InfoRow(
            label: '${s.name(context.lang)} × ${widget.quantity}',
            value: Fmt.money(context, s.price * widget.quantity),
          ),
          InfoRow(
            label: l.deliveryFee,
            value: fee == 0 ? l.free : Fmt.money(context, fee),
          ),
          if (serviceFee > 0)
            InfoRow(
              label: l.serviceFee,
              value: Fmt.money(context, serviceFee),
            ),
          InfoRow(label: l.paymentMethod, value: l.cash),
          if (widget.address != null && widget.address!.isNotEmpty)
            InfoRow(label: l.deliverTo, value: widget.address!),
          const Divider(height: 20),
          InfoRow(
            label: l.total,
            value: Fmt.money(context, total),
            emphasize: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLength: 300,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l.notesHint,
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, _notes.text),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}
