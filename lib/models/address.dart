class Address {
  final String loc;
  final String str;
  final String nrDom;

  Address({
    required this.loc,
    required this.str,
    required this.nrDom,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      loc: json['loc'] ?? '',
      str: json['str'] ?? '',
      nrDom: json['nr_dom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loc': loc,
      'str': str,
      'nr_dom': nrDom,
    };
  }

  String get fullAddress => '$str $nrDom, $loc';
}
