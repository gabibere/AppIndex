import 'role.dart';

class RolesResponse {
  final String session;
  final int err;
  final String msgErr;
  final int countRoles;
  final List<Role> date;

  RolesResponse({
    required this.session,
    required this.err,
    required this.msgErr,
    required this.countRoles,
    required this.date,
  });

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    return RolesResponse(
      session: json['session']?.toString() ?? '',
      err: json['err'] ?? 1,
      msgErr: json['msg_err'] ?? 'Error',
      countRoles: json['count_roles'] ?? 0,
      date: (json['date'] as List<dynamic>?)
              ?.map((roleJson) => Role.fromJson(roleJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'err': err,
      'msg_err': msgErr,
      'count_roles': countRoles,
      'date': date.map((r) => r.toJson()).toList(),
    };
  }

  bool get isSuccess => err == 0;
}
