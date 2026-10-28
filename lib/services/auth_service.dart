import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get userCurent => _auth.currentUser;
  Stream<User?> get schimbariAuth => _auth.authStateChanges();

  Future<UserCredential> login(String email, String parola) {
    return _auth.signInWithEmailAndPassword(email: email, password: parola);
  }

  Future<UserCredential> inregistreaza(String email, String parola) {
    return _auth.createUserWithEmailAndPassword(email: email, password: parola);
  }

  Future<void> delogare() => _auth.signOut();

  Future<void> resetareParola(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
