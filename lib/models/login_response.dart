import 'locality.dart';

class LoginResponse {
  final String session;
  final int err;
  final String msgErr;
  final List<Locality> localit;

  LoginResponse({
    required this.session,
    required this.err,
    required this.msgErr,
    required this.localit,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      session: json['session']?.toString() ?? '',
      err: json['err'] ?? 1,
      msgErr: json['msg_err'] ?? 'Error',
      localit: (json['localit'] as List<dynamic>?)
              ?.map((locJson) => Locality.fromJson(locJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'err': err,
      'msg_err': msgErr,
      'localit': localit.map((l) => l.toJson()).toList(),
    };
  }

  bool get isSuccess => err == 0;
}
