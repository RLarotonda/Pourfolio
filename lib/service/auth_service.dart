import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get changes => _auth.userChanges();
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await credential.user!.reload();
  }

  Future<void> reset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> logout() => _auth.signOut();
  static String message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Informe um e-mail válido.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já possui uma conta.',
        'weak-password' =>
          'A senha não atende à política de segurança do projeto.',
        'network-request-failed' => 'Sem conexão. Verifique a internet.',
        'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
        'operation-not-allowed' =>
          'Ative E-mail/Senha no Firebase Authentication.',
        _ => 'Não foi possível concluir. Tente novamente.',
      };
    }
    return 'Não foi possível concluir. Verifique sua conexão e tente novamente.';
  }
}
