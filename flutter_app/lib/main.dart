import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/network/api_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Налаштування орієнтації (portrait — мобільний додаток)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Ініціалізація dio HTTP client з JWT Interceptor
  ApiService.instance.init();

  // TODO: Firebase init для FCM push-нотифікацій
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MedCareApp());
}
