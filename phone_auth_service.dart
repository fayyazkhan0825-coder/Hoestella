import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  /// Send OTP to phone number (format: +91XXXXXXXXXX)
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only, automatic SMS reading)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(minutes: 2),
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP entered by user
  Future<void> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Invalid OTP: $e');
    }
  }

  /// Link phone to existing user (post-signup verification)
  Future<void> linkPhoneToUser(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.linkWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(minutes: 2),
      );
    } catch (e) {
      throw Exception('Failed to link phone: $e');
    }
  }

  /// Confirm phone link with OTP
  Future<void> confirmPhoneLinkWithOTP(String otp) async {
    try {
      final user = _auth.currentUser;
      if (user == null || _verificationId == null) {
        throw Exception('No active verification');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await user.linkWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to confirm phone: $e');
    }
  }

  /// Check if phone is verified
  bool isPhoneVerified() {
    return _auth.currentUser?.phoneNumber != null &&
        _auth.currentUser!.phoneNumber!.isNotEmpty;
  }

  /// Get current user's phone number
  String? getCurrentUserPhone() {
    return _auth.currentUser?.phoneNumber;
  }

  /// Resend OTP (uses cached resend token)
  Future<void> resendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(minutes: 2),
      );
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }
}
