import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// VIN (serie șasiu, ISO 3779): exact 17 caractere, litere mari A-Z fără
/// I/O/Q (confundabile cu 1/0) și cifre. Eliminăm orice spațiu/linie nouă
/// introdusă de OCR în mijlocul seriei înainte de a căuta potrivirea.
final _vinRegex = RegExp(r'[A-HJ-NPR-Z0-9]{17}');

/// Fotografiază cu camera (apelantul alege sursa) și recunoaște textul
/// on-device (ML Kit, gratuit, fără rețea) căutând un VIN valid în el.
/// Întoarce `null` dacă nu găsește nimic care să arate ca un VIN.
Future<String?> recunoasteVinDinFisier(String caleFisier) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final rezultat = await recognizer.processImage(
      InputImage.fromFilePath(caleFisier),
    );
    final textCurat = rezultat.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    return _vinRegex.firstMatch(textCurat)?.group(0);
  } finally {
    await recognizer.close();
  }
}
