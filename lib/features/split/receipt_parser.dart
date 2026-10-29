/// One purchasable line on a scanned receipt.
class ReceiptItem {
  const ReceiptItem({required this.label, required this.priceMinor});

  final String label;
  final int priceMinor;

  @override
  bool operator ==(Object other) =>
      other is ReceiptItem &&
      other.label == label &&
      other.priceMinor == priceMinor;

  @override
  int get hashCode => Object.hash(label, priceMinor);

  @override
  String toString() => 'ReceiptItem($label, $priceMinor)';
}

class ParsedReceipt {
  const ParsedReceipt({
    required this.merchant,
    required this.items,
    required this.taxMinor,
    required this.tipMinor,
    required this.discountMinor,
    required this.adjustmentMinor,
    required this.subtotalMinor,
    required this.totalMinor,
  });

  final String? merchant;
  final List<ReceiptItem> items;

  /// GST / VAT / cess lines.
  final int taxMinor;

  /// Service charge, tip, gratuity.
  final int tipMinor;

  /// Discounts and coupons (positive number, subtracted).
  final int discountMinor;

  /// Round-off and similar ± adjustments.
  final int adjustmentMinor;
  final int? subtotalMinor;
  final int? totalMinor;

  int get itemsMinor => items.fold(0, (sum, i) => sum + i.priceMinor);

  /// Everything on top of the items, to be spread proportionally. When the
  /// printed total is readable it wins (it captures lines OCR mislabelled).
  int get extrasMinor => totalMinor != null
      ? totalMinor! - itemsMinor
      : taxMinor + tipMinor + adjustmentMinor - discountMinor;

  int get billTotalMinor => itemsMinor + extrasMinor;
}

/// Turns OCR text lines (top to bottom) from a restaurant bill into line
/// items plus tax / tip / discount, for the receipt itemizer.
///
/// Prices are read from the end of a line. ML Kit often splits a receipt's
/// columns into separate lines, so a line holding only a price is attached to
/// the label line before it.
abstract final class ReceiptParser {
  static final RegExp _trailingPrice = RegExp(
    r'(?<=\s|^)(-)?\s*(?:₹|rs\.?|inr|\$)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:[.,](\d{2}))?\s*$',
    caseSensitive: false,
  );
  static final RegExp _priceOnly = RegExp(
    r'^\s*(-)?\s*(?:₹|rs\.?|inr|\$)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:[.,](\d{2}))?\s*$',
    caseSensitive: false,
  );
  static final RegExp _quantity = RegExp(
    r'\s+(?:\d+\s*[x×@*]\s*[\d.,]+|[x×]\s*\d+|\d+\s*(?:pcs?|nos?|qty))\s*$',
    caseSensitive: false,
  );
  static final RegExp _letters = RegExp(r'[A-Za-z]{2,}');

  static final _total = RegExp(
    r'\b(grand\s*total|net\s*(amount|payable|total)|amount\s*payable|bill\s*amount|total\s*amount|total\s*due|^total)\b',
    caseSensitive: false,
  );
  static final _subtotal = RegExp(
    r'\b(sub\s*-?\s*total|item\s*total|food\s*total)\b',
    caseSensitive: false,
  );
  static final _tax = RegExp(
    r'\b(c\s*gst|s\s*gst|i\s*gst|u\s*gst|gst|vat|tax(es)?|cess)\b',
    caseSensitive: false,
  );
  static final _tip = RegExp(
    r'\b(service\s*(charge|chg|fee)|tip|gratuity|delivery\s*(fee|charge)|packing\s*(charge|fee)|container\s*charge)\b',
    caseSensitive: false,
  );
  static final _discount = RegExp(
    r'\b(discount|disc|coupon|promo|offer|savings?|off)\b',
    caseSensitive: false,
  );
  static final _adjustment = RegExp(
    r'\b(round\s*(off|ing)|rounding|adjustment)\b',
    caseSensitive: false,
  );
  static final _noise = RegExp(
    r'\b(date|time|bill\s*no|invoice|inv\s*no|order\s*(no|id)|table|tbl|cover|pax|'
    r'cashier|server|steward|waiter|phone|ph|mob|tel|gstin|fssai|cin|pan|'
    r'thank|visit|again|cash|change|card|upi|paid|tender|balance|qty|rate|amount|'
    r'item|description|particulars|kot|token)\b',
    caseSensitive: false,
  );

  static ParsedReceipt parse(List<String> lines) {
    final cleaned = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];

    String? merchant;
    final items = <ReceiptItem>[];
    var tax = 0, tip = 0, discount = 0, adjustment = 0;
    int? subtotal, total;
    String? pendingLabel;

    void classify(String label, int priceMinor, bool negative) {
      final value = negative ? -priceMinor : priceMinor;
      if (_subtotal.hasMatch(label)) {
        subtotal = priceMinor;
      } else if (_total.hasMatch(label)) {
        total = priceMinor;
      } else if (_adjustment.hasMatch(label)) {
        adjustment += value;
      } else if (_discount.hasMatch(label)) {
        discount += priceMinor;
      } else if (_tip.hasMatch(label)) {
        tip += priceMinor;
      } else if (_tax.hasMatch(label)) {
        tax += priceMinor;
      } else if (!_noise.hasMatch(label) &&
          _letters.hasMatch(label) &&
          !negative) {
        final name = label.replaceFirst(_quantity, '').trim();
        if (name.isNotEmpty && priceMinor > 0) {
          items.add(ReceiptItem(label: name, priceMinor: priceMinor));
        }
      }
    }

    for (final line in cleaned) {
      final priceOnly = _priceOnly.firstMatch(line);
      if (priceOnly != null) {
        if (pendingLabel != null) {
          classify(pendingLabel, _minor(priceOnly), priceOnly[1] != null);
          pendingLabel = null;
        }
        continue;
      }
      final trailing = _trailingPrice.firstMatch(line);
      final label = trailing == null
          ? line
          : line.substring(0, trailing.start).trim();
      if (trailing == null || !_letters.hasMatch(label)) {
        if (_letters.hasMatch(line)) {
          if (merchant == null && items.isEmpty && !_noise.hasMatch(line)) {
            merchant = line;
          } else {
            pendingLabel = line;
          }
        }
        continue;
      }
      pendingLabel = null;
      classify(label, _minor(trailing), trailing[1] != null);
    }

    return ParsedReceipt(
      merchant: merchant,
      items: List.unmodifiable(items),
      taxMinor: tax,
      tipMinor: tip,
      discountMinor: discount,
      adjustmentMinor: adjustment,
      subtotalMinor: subtotal,
      totalMinor: total,
    );
  }

  static int _minor(RegExpMatch m) {
    final integer = int.parse(m[2]!.replaceAll(',', ''));
    final fraction = int.tryParse(m[3] ?? '') ?? 0;
    return integer * 100 + fraction;
  }
}

/// An OCR'd text line and its bounding box (image pixels).
class OcrLine {
  const OcrLine(
    this.text, {
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Rebuilds visual rows from OCR lines: lines whose vertical centres sit
/// within ~60% of a line height are one row, read left to right. This joins
/// "Mango Lassi" and "120.00" that ML Kit reported as separate blocks.
List<String> receiptRows(List<OcrLine> lines) {
  final sorted = [...lines.where((l) => l.text.trim().isNotEmpty)]
    ..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null) {
      final rowCenter =
          row.map((l) => l.centerY).reduce((a, b) => a + b) / row.length;
      final rowHeight = row
          .map((l) => l.height)
          .reduce((a, b) => a < b ? a : b);
      final tolerance =
          0.6 * (line.height < rowHeight ? line.height : rowHeight);
      if ((line.centerY - rowCenter).abs() <= tolerance) {
        row.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return [
    for (final row in rows)
      (row..sort((a, b) => a.left.compareTo(b.left)))
          .map((l) => l.text.trim())
          .join(' '),
  ];
}
