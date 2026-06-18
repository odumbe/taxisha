import 'firebase_options.dart' as staging;
import 'firebase_options_prod.dart' as prod;
import 'package:firebase_core/firebase_core.dart';

/// Set this to true when building for production.
/// Keep false during development so you always hit the staging
/// Firebase project and never touch live data by accident.
const bool kUseProdFirebase = false;

FirebaseOptions get currentFirebaseOptions {
  return kUseProdFirebase
      ? prod.DefaultFirebaseOptions.currentPlatform
      : staging.DefaultFirebaseOptions.currentPlatform;
}