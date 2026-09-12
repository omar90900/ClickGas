import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/repositories/order_repository.dart';
import '../../widgets/common.dart';

/// Places the same order again (same service, quantity, spot and notes),
/// typically after it expired. True when the new order was placed.
Future<bool> reorder(BuildContext context, GasOrder order) async {
  final l = context.l10n;
  if (!await confirmDialog(context, l.orderAgainConfirm, confirmLabel: l.orderAgain)) {
    return false;
  }
  if (!context.mounted) return false;
  try {
    await context.read<OrderRepository>().create(
          customerId: order.customerId,
          serviceId: order.serviceId,
          quantity: order.quantity,
          paymentMethod: PaymentMethod.cash,
          lat: order.deliveryLat,
          lng: order.deliveryLng,
          address: order.deliveryAddress,
          notes: order.notes,
        );
    if (context.mounted) showSnack(context, l.orderPlaced);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, failureText(context, e), error: true);
    return false;
  }
}
