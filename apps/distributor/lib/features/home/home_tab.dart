import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/driver_repository.dart';
import '../../data/tracking_service.dart';
import '../../state/active_orders_controller.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';

/// Live map (driver + accepted orders) with the driver panel underneath:
/// driver info, cylinders on board and the online switch.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _amman = LatLng(31.9539, 35.9106);

  GoogleMapController? _map;
  bool _toggling = false;
  bool _resumeTried = false;
  int? _stock;
  Timer? _stockSave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnMe());
  }

  @override
  void dispose() {
    _stockSave?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _centerOnMe() async {
    final tracking = context.read<TrackingService>();
    final p = tracking.position ?? await tracking.locateOnce();
    if (p != null && mounted) {
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 15),
      );
    }
  }

  Future<void> _setOnline(bool online) async {
    final tracking = context.read<TrackingService>();
    final session = context.read<DriverSession>();
    final l = context.l10n;
    setState(() => _toggling = true);
    try {
      if (online) {
        await tracking.goOnline(
          session.driver!.id,
          notificationTitle: l.trackingNotificationTitle,
          notificationText: l.trackingNotificationText,
        );
        await _centerOnMe();
      } else {
        await tracking.goOffline();
      }
      await session.refreshDriver();
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.issue == LocationIssue.serviceDisabled
              ? l.locationServiceDisabled
              : l.locationPermissionDenied),
          action: SnackBarAction(
            label: l.openSettings,
            onPressed: () =>
                context.read<LocationService>().openSettingsFor(e.issue),
          ),
        ),
      );
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  /// App restarted while the driver was online: resume sharing location.
  void _maybeResume(DriverProfile driver, TrackingService tracking) {
    if (_resumeTried || !driver.isOnline || !driver.isVerified) return;
    if (tracking.isOnline) return;
    _resumeTried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setOnline(true);
    });
  }

  void _changeStock(DriverProfile driver, int delta) {
    final next = ((_stock ?? driver.cylindersOnBoard) + delta).clamp(0, 500);
    setState(() => _stock = next);
    _stockSave?.cancel();
    _stockSave = Timer(const Duration(milliseconds: 700), () async {
      final session = context.read<DriverSession>();
      final l = context.l10n;
      try {
        final updated = await context
            .read<DriverRepository>()
            .update(driver.id, {'cylinders_on_board': next});
        session.setDriver(updated);
        if (mounted) {
          setState(() => _stock = null);
          showSnack(context, l.cylindersUpdated);
        }
      } catch (_) {
        if (mounted) showSnack(context, l.errorGeneric, error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DriverSession>();
    final tracking = context.watch<TrackingService>();
    final active = context.watch<ActiveOrdersController>();
    final driver = session.driver!;
    _maybeResume(driver, tracking);

    final me = tracking.position;
    final start = me != null
        ? LatLng(me.latitude, me.longitude)
        : driver.lat != null
            ? LatLng(driver.lat!, driver.lng!)
            : _amman;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: start, zoom: 14),
                myLocationEnabled: me != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) => _map = c,
                markers: {
                  for (final o in active.orders)
                    Marker(
                      markerId: MarkerId(o.id),
                      position: LatLng(o.lat, o.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        switch (o.status) {
                          OrderStatus.onTheWay => BitmapDescriptor.hueOrange,
                          OrderStatus.delivered => BitmapDescriptor.hueGreen,
                          _ => BitmapDescriptor.hueAzure,
                        },
                      ),
                      infoWindow: InfoWindow(
                        title: o.customerName,
                        snippet:
                            '${context.l10n.orderNumber(o.orderNumber)} · ${context.l10n.quantityCount(o.quantity)}',
                      ),
                    ),
                },
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 12,
                child: Material(
                  elevation: 2,
                  color: context.colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(99),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_rounded,
                            size: 16, color: context.accent),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.activeOrdersCount(active.count),
                          style: context.text.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 14,
                end: 14,
                child: FloatingActionButton.small(
                  heroTag: 'driver-locate',
                  tooltip: context.l10n.myLocation,
                  backgroundColor: context.colors.surfaceContainerLowest,
                  foregroundColor: context.accent,
                  onPressed: _centerOnMe,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
        ),
        _DriverPanel(
          driver: driver,
          name: session.profile?.fullName ?? '',
          online: tracking.isOnline,
          toggling: _toggling,
          stock: _stock ?? driver.cylindersOnBoard,
          onStock: (d) => _changeStock(driver, d),
          onOnline: _setOnline,
          onRefresh: session.refreshDriver,
        ),
      ],
    );
  }
}

class _DriverPanel extends StatelessWidget {
  const _DriverPanel({
    required this.driver,
    required this.name,
    required this.online,
    required this.toggling,
    required this.stock,
    required this.onStock,
    required this.onOnline,
    required this.onRefresh,
  });

  final DriverProfile driver;
  final String name;
  final bool online;
  final bool toggling;
  final int stock;
  final ValueChanged<int> onStock;
  final ValueChanged<bool> onOnline;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final radius = context.watch<AppConfig>().driverRadiusKm;
    final vehicle = [
      driver.vehiclePlate,
      if (driver.vehicleType.isNotEmpty) vehicleTypeLabel(l, driver.vehicleType),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, -2)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(
                  url: context.watch<DriverSession>().profile?.avatarUrl,
                  name: name,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (vehicle.isNotEmpty)
                        Text(vehicle, style: context.text.bodySmall),
                      if (driver.agencyName.isNotEmpty)
                        Text(
                          driver.agencyName,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DriverStatusTag(driver: driver),
                    const SizedBox(height: 4),
                    RatingStars(value: driver.ratingAvg),
                  ],
                ),
              ],
            ),
            if (!driver.isVerified) ...[
              const SizedBox(height: 12),
              DriverStatusBanner(driver: driver, onRefresh: onRefresh),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.propane_tank_rounded, color: context.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.cylindersOnBoard,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: stock > 0 ? () => onStock(-1) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$stock',
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => onStock(1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: online
                    ? AppColors.brand
                    : context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    online
                        ? Icons.wifi_tethering_rounded
                        : Icons.power_settings_new_rounded,
                    color: online ? AppColors.onBrand : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          online ? l.online : l.offline,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: online ? AppColors.onBrand : null,
                          ),
                        ),
                        Text(
                          online ? l.onlineDesc(Fmt.km(radius)) : l.offlineDesc,
                          style: context.text.bodySmall?.copyWith(
                            color: online
                                ? AppColors.onBrand.withValues(alpha: 0.8)
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (toggling)
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else
                    Switch(
                      value: online,
                      activeTrackColor: AppColors.onBrand,
                      activeThumbColor: AppColors.brand,
                      onChanged: driver.isVerified ? onOnline : null,
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
