import 'user_model.dart';

/// Auth response returned from the login endpoint.
class LoginResponseModel {
  const LoginResponseModel({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
  });

  final UserModel user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final normalizedTokenSource = _extractTokenSource(json);

    return LoginResponseModel(
      user: UserModel.fromJson(json),
      accessToken: _readNullableString(normalizedTokenSource, const [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ]),
      refreshToken: _readNullableString(normalizedTokenSource, const [
        'refresh_token',
        'refreshToken',
      ]),
      message: _readNullableString(json, ['message', 'detail']),
    );
  }

  static Map<String, dynamic> _extractTokenSource(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    return json;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
