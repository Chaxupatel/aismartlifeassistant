import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstract definition for application-wide authentication services.
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(String email, String name, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<User?> signInWithGoogle({bool isLogin = true});
  Future<void> updateDisplayName(String name);
  Future<void> reauthenticateAndChangePassword(String currentPassword, String newPassword);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
}

/// Firebase implementation of the [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<User?> signUpWithEmailAndPassword(String email, String name, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
        return _firebaseAuth.currentUser;
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<User?> signInWithGoogle({bool isLogin = true}) async {
    try {
      // Trigger the Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in flow
      if (googleUser == null) return null;

      // Enforce Login vs Signup logic
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(googleUser.email);
      
      if (isLogin && signInMethods.isEmpty) {
        // Log out of google sign in so they aren't stuck on the cached account if they try again
        await _googleSignIn.signOut();
        throw Exception('No account found with this Google email. Please sign up first.');
      }
      
      if (!isLogin && signInMethods.isNotEmpty) {
        // We're signing up, but they already exist
        await _googleSignIn.signOut();
        throw Exception('An account already exists with this Google email. Please log in instead.');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Build a Firebase credential from the Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateDisplayName(String name) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<void> reauthenticateAndChangePassword(String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No signed-in user found.');
      if (user.email == null) {
        throw Exception('Password change is not available for this sign-in method.');
      }
      // Reauthenticate with the current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      // Now safe to update the password
      await user.updatePassword(newPassword);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    // Sign out from both Google and Firebase
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
  }

  Exception _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('The email address is already registered.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'weak-password':
        return Exception('Password is too weak. Choose at least 6 characters.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'operation-not-allowed':
        return Exception('Email/Password authentication is disabled.');
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with this email using a different sign-in method.');
      case 'requires-recent-login':
        return Exception('This operation is sensitive and requires recent authentication. Please log out and log back in to change your password.');
      default:
        return Exception(e.message ?? 'An unknown authentication error occurred.');
    }
  }
}

