class Person {
  final String nume;
  final String pren;
  final int? cnp;
  final int tipPers; // 1 = pf (persoana fizica), 2 = pj (persoana juridica)

  Person({
    required this.nume,
    required this.pren,
    this.cnp,
    required this.tipPers,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      nume: json['nume'] ?? '',
      pren: json['pren'] ?? '',
      cnp: json['cnp'],
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
