import 'package:firebase_core/firebase_core.dart';

/// Firebase options for the EliteChat admin web app.
///
/// These values are the public web app configuration from Firebase Console.
abstract final class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyB8els6m6PxmoBvdkP63bxmY-rPpSLzSJo',
    authDomain: 'e-wallet-1cb99.firebaseapp.com',
    databaseURL:
        'https://e-wallet-1cb99-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'e-wallet-1cb99',
    storageBucket: 'e-wallet-1cb99.firebasestorage.app',
    messagingSenderId: '517785733421',
    appId: '1:517785733421:web:3a4efe450fa8edc8486ba4',
    measurementId: 'G-DDHH88SHW2',
  );
}
