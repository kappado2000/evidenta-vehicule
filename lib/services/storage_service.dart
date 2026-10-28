import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/fisier_atasat.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Urcă un fișier sub `users/{dataOwnerUid}/{subfolder}/{nume unic}` —
  /// aceeași structură de cale ca regulile Storage existente
  /// (poateAccesa(ownerUid), max 30MB, image/* sau application/pdf).
  ///
  /// Primește `XFile` (nu `dart:io File`) ca să funcționeze identic pe
  /// mobil ȘI pe web (previzualizare rapidă, vezi planul de verificare).
  Future<FisierAtasat> urca({
    required String dataOwnerUid,
    required String subfolder,
    required XFile fisier,
    required String numeOriginal,
    required String contentType,
  }) async {
    return urcaBytes(
      dataOwnerUid: dataOwnerUid,
      subfolder: subfolder,
      bytes: await fisier.readAsBytes(),
      numeOriginal: numeOriginal,
      contentType: contentType,
    );
  }

  /// Variantă directă pe bytes — folosită și pentru fișiere alese cu
  /// `file_picker` (PDF-uri), care pe web nu oferă cale de fișier, doar bytes.
  Future<FisierAtasat> urcaBytes({
    required String dataOwnerUid,
    required String subfolder,
    required Uint8List bytes,
    required String numeOriginal,
    required String contentType,
  }) async {
    final numeUnic = '${DateTime.now().millisecondsSinceEpoch}_$numeOriginal';
    final cale = 'users/$dataOwnerUid/$subfolder/$numeUnic';
    final ref = _storage.ref(cale);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    return FisierAtasat(
      name: numeOriginal,
      url: url,
      path: cale,
      type: contentType,
    );
  }

  Future<void> sterge(String path) async {
    if (path.isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // Fișierul poate fi deja șters (ex. document vechi) — nu blocăm UI-ul.
    }
  }
}
