import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyDr_AJGaGli7yC5Ex_RKW3HidgypZOr17U',
            authDomain: 'jobflow-ui-web.firebaseapp.com',
            projectId: 'jobflow-ui-web',
            storageBucket: 'jobflow-ui-web.firebasestorage.app',
            messagingSenderId: '193517135834',
            appId: '1:193517135834:web:e6490d115528e3c585c2e3',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
