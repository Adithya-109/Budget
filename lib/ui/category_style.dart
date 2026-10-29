import 'package:flutter/material.dart';

import '../core/database/enums.dart';
import 'theme.dart';

extension CategoryStyle on TxnCategory {
  IconData get icon => switch (this) {
    TxnCategory.food => Icons.local_pizza_outlined,
    TxnCategory.groceries => Icons.shopping_basket_outlined,
    TxnCategory.transit => Icons.electric_rickshaw_outlined,
    TxnCategory.utilities => Icons.wifi,
    TxnCategory.fun => Icons.celebration_outlined,
    TxnCategory.other => Icons.receipt_long_outlined,
  };

  Color get color => switch (this) {
    TxnCategory.food => SbColors.magma,
    TxnCategory.groceries => SbColors.owed,
    TxnCategory.transit => SbColors.sky,
    TxnCategory.utilities => SbColors.lime,
    TxnCategory.fun => const Color(0xFFC792EA),
    TxnCategory.other => SbColors.paper,
  };
}

extension SourceStyle on TxnSource {
  /// Short tag for rows logged outside the app, or null for manual entries.
  String? get tag => switch (this) {
    TxnSource.app => null,
    TxnSource.applePayShortcut => 'APPLE PAY',
    TxnSource.voiceIntent => 'VOICE',
    TxnSource.androidUpiAuto => 'UPI AUTO',
    TxnSource.ocr => 'SCANNED',
    TxnSource.subscription => 'RECURRING',
  };
}
