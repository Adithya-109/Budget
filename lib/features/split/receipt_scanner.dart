import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'receipt_parser.dart';

part 'receipt_scanner.g.dart';

class ScannedReceipt {
  const ScannedReceipt({required this.imagePath, required this.receipt});

  final String imagePath;
  final ParsedReceipt receipt;
}

/// Camera / gallery → on-device OCR (Apple Vision on iOS, ML Kit on
/// Android, via google_mlkit_text_recognition) → line items.
class ReceiptScanner {
  const ReceiptScanner();

  /// Returns null when the user backs out of the picker.
  Future<ScannedReceipt?> scan({required bool fromCamera}) async {
    final file = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (file == null) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      final lines = [
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              right: line.boundingBox.right,
              bottom: line.boundingBox.bottom,
            ),
      ];
      return ScannedReceipt(
        imagePath: file.path,
        receipt: ReceiptParser.parse(receiptRows(lines)),
      );
    } finally {
      await recognizer.close();
    }
  }
}

@Riverpod(keepAlive: true)
ReceiptScanner receiptScanner(Ref ref) => const ReceiptScanner();
