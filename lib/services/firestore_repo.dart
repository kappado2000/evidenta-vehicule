import 'package:cloud_firestore/cloud_firestore.dart';

/// CRUD generic pe o subcolecție `users/{dataOwnerUid}/{colectie}`, cu
/// convertoare de/la model furnizate de apelant. Toate cele 5 colecții
/// (vehicule, itp, asigurari, revizii, rovinieta) folosesc acest tipar.
class FirestoreRepo<T> {
  final String dataOwnerUid;
  final String colectie;
  final T Function(String id, Map<String, dynamic> data) fromFirestore;
  final Map<String, dynamic> Function(T model) toFirestore;

  FirestoreRepo({
    required this.dataOwnerUid,
    required this.colectie,
    required this.fromFirestore,
    required this.toFirestore,
  });

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore
      .instance
      .collection('users')
      .doc(dataOwnerUid)
      .collection(colectie);

  Stream<List<T>> asculta() {
    return _ref.snapshots().map(
      (snap) => snap.docs
          .map((d) => fromFirestore(d.id, d.data()))
          .toList(growable: false),
    );
  }

  Future<List<T>> listaUnaSingura() async {
    final snap = await _ref.get();
    return snap.docs.map((d) => fromFirestore(d.id, d.data())).toList();
  }

  Future<String> adauga(T model) async {
    final data = toFirestore(model)
      ..['timestamp'] = FieldValue.serverTimestamp();
    final ref = await _ref.add(data);
    return ref.id;
  }

  Future<void> actualizeaza(String id, T model) async {
    final data = toFirestore(model)..['updatedAt'] = FieldValue.serverTimestamp();
    await _ref.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> sterge(String id) => _ref.doc(id).delete();
}
