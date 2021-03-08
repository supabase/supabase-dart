import 'package:gotrue/gotrue.dart' show User;

class AuthUser extends User {
  AuthUser(
      {required String id,
      required Map<String, dynamic> appMetadata,
      required Map<String, dynamic> userMetadata,
      required String aud,
      required String email,
      required String createdAt,
      required String confirmedAt,
      required String lastSignInAt,
      required String role,
      required String updatedAt})
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
