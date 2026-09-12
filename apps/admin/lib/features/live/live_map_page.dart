import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../orders/order_inspector.dart';

/// Open orders (coloured by how long they have waited) and online or busy
/// distributors on one map, refreshed every 10 seconds. OpenStreetMap tiles,
/// no API key (docs/decisions/0009-admin-web-app.md).
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

Color orderPinColor(LiveOrder o, DateTime now) {
  if (o.status != OrderStatus.pending) return AppColors.info;
  return switch (WaitBand.of(o.waited(now))) {
    WaitBand.fresh => AppColors.brandDeep,
    WaitBand.slow => AppColors.warning,
    WaitBand.late => AppColors.danger,
  };
}

class _LiveMapPageState extends State<LiveMapPage> {
  final _map = MapController();
  static const _amman = LatLng(31.9539, 35.9106);

  List<LatLng> _points(LiveMap m) => [
        for (final o in m.orders) LatLng(o.lat, o.lng),
        for (final d in m.drivers) LatLng(d.lat, d.lng),
      ];

  void _fit(LiveMap m) {
    final points = _points(m);
    if (points.isEmpty) {
      _map.move(_amman, 12);
    } else if (points.length == 1) {
      _map.move(points.first, 14);
    } else {
      _map.fitCamera(
        CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(64), maxZoom: 15),
      );
    }
  }

  void _openOrder(BuildContext context, LiveOrder o, Future<void> Function() reload) {
    _map.move(LatLng(o.lat, o.lng), 15);
    showOrderInspector(context, o.id, onChanged: reload);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<LiveMap>(
      load: context.read<AdminRepository>().liveMap,
      refreshEvery: const Duration(seconds: 10),
      builder: (context, data, reload) {
        final now = DateTime.now();
        final map = _buildMap(context, data, now, reload);
        final list = _LiveList(
          data: data,
          now: now,
          onOrder: (o) => _openOrder(context, o, reload),
          onDriver: (d) => _map.move(LatLng(d.lat, d.lng), 15),
        );
        return LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 1000
              ? Row(children: [
                  Expanded(child: map),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 360, child: list),
                ])
              : Column(children: [
                  Expanded(flex: 3, child: map),
                  const Divider(height: 1),
                  Expanded(flex: 2, child: list),
                ]),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, LiveMap data, DateTime now, Future<void> Function() reload) {
    final l = context.l10n;
    final points = _points(data);
    final center = points.isEmpty
        ? _amman
        : LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
          );

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: center, initialZoom: points.isEmpty ? 12 : 13, minZoom: 6),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.clickgas.admin',
            ),
            MarkerLayer(
              markers: [
                for (final d in data.drivers)
                  Marker(
                    point: LatLng(d.lat, d.lng),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: '${d.fullName} · ${d.vehiclePlate}\n'
                          '${l.cylindersShort(d.cylindersOnBoard)} · ${l.openOrdersShort(d.openOrders)}\n'
                          '${Fmt.ago(context, d.locationUpdatedAt)}',
                      child: _DriverPin(stale: d.isStale(now), busy: d.openOrders > 0),
                    ),
                  ),
                for (final o in data.orders)
                  Marker(
                    point: LatLng(o.lat, o.lng),
                    width: 34,
                    height: 34,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _openOrder(context, o, reload),
                        child: Tooltip(
                          message: '#${o.orderNumber} · ${o.customerName}\n'
                              '${orderStatusLabel(l, o.status)} · ${Fmt.duration(context, o.waited(now))}',
                          child: OrderPin(color: orderPinColor(o, now), label: '${o.quantity}'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => openExternal('https://www.openstreetmap.org/copyright'),
                ),
              ],
            ),
          ],
        ),
        const PositionedDirectional(top: 12, start: 12, child: _Legend()),
        PositionedDirectional(
          top: 12,
          end: 12,
          child: Card(
            child: IconButton(
              tooltip: l.fitAll,
              icon: const Icon(Icons.fit_screen_rounded),
              onPressed: () => _fit(data),
            ),
          ),
        ),
      ],
    );
  }
}

/// A round pin with the number of cylinders.
class OrderPin extends StatelessWidget {
  const OrderPin({super.key, required this.color, required this.label, this.size = 30});
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

class _DriverPin extends StatelessWidget {
  const _DriverPin({required this.stale, required this.busy});
  final bool stale;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = stale ? Colors.grey : (busy ? AppColors.info : AppColors.brandDeep);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Icon(Icons.local_shipping_rounded, size: 20, color: color),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget row(Color c, String text, {bool ring = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ring ? Colors.white : c,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: ring ? 2.5 : 0),
                ),
              ),
              const SizedBox(width: 8),
              Text(text, style: context.text.labelMedium),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            row(AppColors.brandDeep, l.legendFresh),
            row(AppColors.warning, l.legendSlow),
            row(AppColors.danger, l.legendLate),
            row(AppColors.info, l.legendAssigned),
            row(AppColors.brandDeep, l.legendDriver, ring: true),
            row(Colors.grey, l.legendStale, ring: true),
          ],
        ),
      ),
    );
  }
}

class _LiveList extends StatelessWidget {
  const _LiveList({required this.data, required this.now, required this.onOrder, required this.onDriver});

  final LiveMap data;
  final DateTime now;
  final ValueChanged<LiveOrder> onOrder;
  final ValueChanged<LiveDriver> onDriver;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final names = {for (final d in data.drivers) d.id: d.fullName};
    // Longest-waiting pending orders first, then orders on delivery.
    final orders = [...data.orders]..sort((a, b) {
        final ap = a.status == OrderStatus.pending ? 0 : 1;
        final bp = b.status == OrderStatus.pending ? 0 : 1;
        if (ap != bp) return ap - bp;
        return (a.createdAt ?? now).compareTo(b.createdAt ?? now);
      });

    Widget header(String text) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
          child: Text(text, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        header(l.liveOpenOrders(orders.length)),
        if (orders.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(l.noOpenOrders)),
        for (final o in orders)
          ListTile(
            dense: true,
            leading: OrderPin(color: orderPinColor(o, now), label: '${o.quantity}', size: 28),
            title: Text('#${o.orderNumber} · ${o.customerName}', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              o.status == OrderStatus.pending
                  ? l.waitingFor(Fmt.duration(context, o.waited(now)))
                  : '${orderStatusLabel(l, o.status)} · ${names[o.driverId] ?? ''}',
            ),
            onTap: () => onOrder(o),
          ),
        const Divider(),
        header(l.liveDrivers(data.drivers.length)),
        if (data.drivers.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(l.noDriversOnline)),
        for (final d in data.drivers)
          ListTile(
            dense: true,
            leading: UserAvatar(url: d.avatarUrl, name: d.fullName, radius: 16),
            title: Text(d.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${d.vehiclePlate} · ${l.cylindersShort(d.cylindersOnBoard)} · ${l.openOrdersShort(d.openOrders)}',
            ),
            trailing: Dot(
              d.isStale(now) ? Colors.grey : AppColors.brandDeep,
              tooltip: d.isStale(now) ? l.legendStale : l.online,
            ),
            onTap: () => onDriver(d),
          ),
      ],
    );
  }
}
