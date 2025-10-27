class Locality {
  final int idLoc;
  final String loc;

  Locality({
    required this.idLoc,
    required this.loc,
  });

  factory Locality.fromJson(Map<String, dynamic> json) {
    return Locality(
      idLoc: json['id_loc'] ?? 0,
      loc: json['loc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_loc': idLoc,
      'loc': loc,
    };
  }
}
