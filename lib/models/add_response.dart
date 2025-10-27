class AddResponse {
  final String session;
  final int err;
  final String msgErr;

  AddResponse({
    required this.session,
    required this.err,
    required this.msgErr,
  });

  factory AddResponse.fromJson(Map<String, dynamic> json) {
    return AddResponse(
      session: json['session']?.toString() ?? '',
      err: json['err'] ?? 1,
      msgErr: json['msg_err'] ?? 'Error',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'err': err,
      'msg_err': msgErr,
    };
  }

  bool get isSuccess => err == 0;
}
