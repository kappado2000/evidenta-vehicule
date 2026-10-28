// `google_mlkit_text_recognition` importă `dart:io` intern (pentru
// `InputImage.fromFile`), deci nu poate fi compilat pentru web — chiar
// dacă apelul e păzit cu `kIsWeb` la runtime, importul însuși ar rupe
// `flutter build web`. Exportul condiționat alege implementarea reală doar
// pe platforme unde `dart:io` există (iOS/Android), altfel varianta de
// rezervă (`vin_scanner_stub.dart`), care nu are nicio dependență nativă.
export 'vin_scanner_stub.dart' if (dart.library.io) 'vin_scanner_mobile.dart';
