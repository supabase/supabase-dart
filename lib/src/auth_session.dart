import 'package:gotrue/gotrue.dart' show Session, User;

class AuthSession extends Session {
  AuthSession({
    required String accessToken,
    int? expiresIn,
    String? refreshToken,
    required String tokenType,
    User? user,
  }) : super(
          accessToken: accessToken,
          expiresIn: expiresIn,
          refreshToken: refreshToken,
          tokenType: tokenType,
          user: user,
        );
}
