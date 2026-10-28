/// Obiect fișier atașat (poză/PDF), formă identică cu cea scrisă de PWA:
/// `{ name, url, path, type }` în Firestore.
class FisierAtasat {
  final String name;
  final String url;
  final String path;
  final String type;

  const FisierAtasat({
    required this.name,
    required this.url,
    required this.path,
    required this.type,
  });

  factory FisierAtasat.fromMap(Map<String, dynamic> map) {
    return FisierAtasat(
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      path: map['path'] as String? ?? '',
      type: map['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'url': url, 'path': path, 'type': type};
  }

  static List<FisierAtasat> listaFromDynamic(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((m) => FisierAtasat.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  static List<Map<String, dynamic>> listaToMap(List<FisierAtasat> fisiere) {
    return fisiere.map((f) => f.toMap()).toList();
  }
}
