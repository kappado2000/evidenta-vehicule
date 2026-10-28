/// Implementare de rezervă pentru web, unde `google_mlkit_text_recognition`
/// nu e disponibil (și nici nu poate fi compilat — pachetul importă
/// `dart:io` intern). Nu e apelată niciodată: butonul de scanare e ascuns
/// pe web (`kIsWeb`), dar fișierul trebuie să existe ca să satisfacă
/// importul condiționat din `vin_scanner.dart`.
Future<String?> recunoasteVinDinFisier(String caleFisier) async {
  throw UnsupportedError('Scanarea VIN nu e disponibilă pe web.');
}
