import 'person.dart';
import 'address.dart';
import 'tax.dart';

class Role {
  final int idRol;
  final String rol; // Changed from int to String as per API spec
  final Person pers;
  final Address addr;
  final List<Tax> tax;

  Role({
    required this.idRol,
    required this.rol,
    required this.pers,
    required this.addr,
    required this.tax,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    // Handle both string and int for backward compatibility
    final rolValue = json['rol'];
    final rolString = rolValue is String
        ? rolValue
        : rolValue is int
            ? rolValue.toString()
            : rolValue?.toString() ?? '0';

    return Role(
      idRol: json['id_rol'] ?? 0,
      rol: rolString,
      pers: Person.fromJson(json['pers'] ?? {}),
      addr: Address.fromJson(json['addr'] ?? {}),
      tax: (json['tax'] as List<dynamic>?)
              ?.map((taxJson) => Tax.fromJson(taxJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rol': idRol,
      'rol': rol,
      'pers': pers.toJson(),
      'addr': addr.toJson(),
      'tax': tax.map((t) => t.toJson()).toList(),
    };
  }
}
