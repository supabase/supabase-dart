import 'package:gotrue/gotrue.dart' show User;

class AuthUser extends User {
  AuthUser(
      {String id,
      Map<String, dynamic> appMetadata,
      Map<String, dynamic> userMetadata,
      String aud,
      String email,
      String createdAt,
      String confirmedAt,
      String lastSignInAt,
      String role,
      String updatedAt})
      : super(
            id: id,
            appMetadata: appMetadata,
            userMetadata: userMetadata,
            aud: aud,
            email: email,
            createdAt: createdAt,
            confirmedAt: confirmedAt,
            lastSignInAt: lastSignInAt,
            role: role,
            updatedAt: updatedAt);
}
