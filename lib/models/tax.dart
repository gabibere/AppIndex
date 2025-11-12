class Tax {
  final int idTipTaxa;
  final int idTax2rol;
  final int idTax2bord;
  final String numeTaxa;
  final String unitMasura;
  final int valOld;
  final String dataCitireOld;
  final String
      tipCitireOld; // C-citire, E-Estimat, P-Pausal, F-Fara facturare, X-Neutilizat
  final int? valNewP;
  final int? valNewE;
  final String
      inactiva; // Added as per API spec: 0=active, 1=inactive (notification with red)
  final String
      perioadaIndex; // Added as per API spec: "FEB2025" or "01-10 31-12 2025"

  Tax({
    required this.idTipTaxa,
    required this.idTax2rol,
    required this.idTax2bord,
    required this.numeTaxa,
    required this.unitMasura,
    required this.valOld,
    required this.dataCitireOld,
    required this.tipCitireOld,
    this.valNewP,
    this.valNewE,
    this.inactiva = '0', // Default to active
    this.perioadaIndex = '', // Default to empty
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    // Handle inactiva: can be int (0/1) or string, convert to string
    final inactivaValue = json['inactiva'];
    final inactivaString = inactivaValue is String
        ? inactivaValue
        : inactivaValue is int
            ? inactivaValue.toString()
            : inactivaValue?.toString() ?? '0';

    return Tax(
      idTipTaxa: json['id_tip_taxa'] ?? 0,
      idTax2rol: json['id_tax2rol'] ?? 0,
      idTax2bord: json['id_tax2bord'] ?? 0,
      numeTaxa: json['nume_taxa'] ?? '',
      unitMasura: json['unit_masura'] ?? '',
      valOld: json['val_old'] ?? 0,
      dataCitireOld: json['data_citire_old'] ?? '',
      tipCitireOld: json['tip_citire_old'] ?? 'C',
      valNewP: json['val_new_p'],
      valNewE: json['val_new_e'],
      inactiva: inactivaString,
      perioadaIndex: json['perioada_index']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tip_taxa': idTipTaxa,
      'id_tax2rol': idTax2rol,
      'id_tax2bord': idTax2bord,
      'nume_taxa': numeTaxa,
      'unit_masura': unitMasura,
      'val_old': valOld,
      'data_citire_old': dataCitireOld,
      'tip_citire_old': tipCitireOld,
      'val_new_p': valNewP,
      'val_new_e': valNewE,
      'inactiva': inactiva,
      'perioada_index': perioadaIndex,
    };
  }

  bool get isReading => tipCitireOld == 'C';
  bool get isEstimated => tipCitireOld == 'E';
  bool get isPausal => tipCitireOld == 'P';
  bool get isWithoutBilling => tipCitireOld == 'F';
  bool get isUnused => tipCitireOld == 'X';
  bool get isInactive => inactiva == '1'; // Check if tax is inactive
}
