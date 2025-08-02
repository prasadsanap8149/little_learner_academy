import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/game_provider.dart';
import 'services/auth_service.dart';
import 'services/navigation_service.dart';
import 'services/ui_service.dart';
import 'services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch(e) {
    if(e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }
  
  // Initialize offline service
  await OfflineService().initialize();
  
  runApp(const LittleLearnersApp());
}

class LittleLearnersApp extends StatelessWidget {
  const LittleLearnersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameProvider()),
        Provider<AuthService>(create: (context) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Little Learners Academy',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: UITheme.lightTheme,
        routes: NavigationService.getRoutes(),
        initialRoute: '/',
      ),
    );
  }
}
