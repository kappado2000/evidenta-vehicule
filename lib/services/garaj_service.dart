import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Rezultatul `initializeazaGaraj` — vezi funcția identică din
/// functions/index.js a PWA-ului, neschimbată de rescrierea Flutter.
class InfoGaraj {
  final String garajId;
  final String ownerUid;
  final bool esteProprietar;
  final Map<String, dynamic> membri;

  const InfoGaraj({
    required this.garajId,
    required this.ownerUid,
    required this.esteProprietar,
    required this.membri,
  });

  /// uid-ul sub care se citesc/scriu TOATE datele (vehicule, itp, etc.) —
  /// propriul uid dacă e proprietar, altfel uid-ul proprietarului garajului.
  String get dataOwnerUid => ownerUid;
}

class GarajService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Apelată o dată, imediat după login. Rezolvă `dataOwnerUid` pentru restul
  /// sesiunii — fiecare citire/scriere din aplicație trebuie să treacă prin
  /// valoarea întoarsă de aici, niciodată prin `currentUser.uid` direct.
  Future<InfoGaraj> initializeaza() async {
    final rezultat = await _functions
        .httpsCallable('initializeazaGaraj')
        .call<Map<String, dynamic>>();
    final data = rezultat.data;
    return InfoGaraj(
      garajId: data['garajId'] as String,
      ownerUid: data['ownerUid'] as String,
      esteProprietar: data['esteProprietar'] as bool,
      membri: Map<String, dynamic>.from(data['membri'] as Map? ?? {}),
    );
  }

  Future<bool> invitaMembru(String email) async {
    final rezultat = await _functions
        .httpsCallable('invitaMembruGaraj')
        .call<Map<String, dynamic>>({'email': email});
    return rezultat.data['emailTrimis'] as bool? ?? false;
  }

  Future<void> eliminaMembru(String uid) async {
    await _functions.httpsCallable('eliminaMembruGaraj').call({'uid': uid});
  }

  /// Document `garaje/{garajId}` — doar citire, scrierile trec prin funcții.
  Stream<DocumentSnapshot<Map<String, dynamic>>> ascultaGaraj(String garajId) {
    return _db.collection('garaje').doc(garajId).snapshots();
  }
}
