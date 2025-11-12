class Person {
  final String nume;
  final String pren;
  final String? cnp; // Changed from int? to String? as per API spec
  final int tipPers; // 1 = pf (persoana fizica), 2 = pj (persoana juridica)

  Person({
    required this.nume,
    required this.pren,
    this.cnp,
    required this.tipPers,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    // Handle cnp: can be null, int, or string, convert to string
    final cnpValue = json['cnp'];
    final cnpString = cnpValue == null
        ? null
        : cnpValue is String
            ? (cnpValue.isEmpty ? null : cnpValue)
            : cnpValue.toString();

    return Person(
      nume: json['nume'] ?? '',
      pren: json['pren'] ?? '',
      cnp: cnpString,
      tipPers: json['tip_pers'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nume': nume,
      'pren': pren,
      'cnp': cnp,
      'tip_pers': tipPers,
    };
  }

  String get fullName => '$nume $pren';
  bool get isPhysicalPerson => tipPers == 1;
  bool get isLegalPerson => tipPers == 2;
}
