import 'user_model.dart';

/// Auth response returned from the login endpoint.
class LoginResponseModel {
  const LoginResponseModel({required this.user, this.token, this.message});

  final UserModel user;
  final String? token;
  final String? message;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final normalizedUser = _extractUserSource(json);
    final normalizedTokenSource = _extractTokenSource(json);

    return LoginResponseModel(
      user: UserModel.fromJson(normalizedUser),
      token: _readNullableString(normalizedTokenSource, [
        'token',
        'access_token',
        'accessToken',
        'jwt',
      ]),
      message: _readNullableString(json, ['message', 'detail']),
    );
  }

  static Map<String, dynamic> _extractUserSource(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedUser = nestedData['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
    }

    final nestedUser = json['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }

    return json;
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
