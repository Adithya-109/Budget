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

  /// Category hue from the theme's tokens, so it reads in both modes.
  Color colorIn(SplitBurnTokens t) => switch (this) {
    TxnCategory.food => t.survivalMagmaEnd,
    TxnCategory.groceries => t.owedToMe,
    TxnCategory.transit => t.info,
    TxnCategory.utilities => t.trialAmber,
    TxnCategory.fun => t.nudgeViolet,
    TxnCategory.other => t.textSecondary,
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
