import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'views/home_view.dart';
import 'views/auth/sign_in_view.dart';
import 'views/auth/terms_privacy_consent_view.dart';
import 'views/auth/email_verification_pending_view.dart';
import 'views/main_navigation_view.dart';
import 'providers/auth_provider.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web用のCORS設定
  if (kIsWeb) {
    // Web用の画像読み込み設定
    debugPrint('Running on web platform');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // エラーが発生してもアプリは起動する
  }
  
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GrouMap',
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE75B41),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/signin': (context) => const SignInView(),
        '/signup': (context) => const TermsPrivacyConsentView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final PushNotificationService _pushNotificationService;
  ProviderSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _pushNotificationService = ref.read(pushNotificationServiceProvider);
    _pushNotificationService.initialize();

    _authStateSubscription = ref.listenManual(authStateProvider, (previous, next) {
      if (next is AsyncData<User?>) {
        final user = next.value;
        if (user != null) {
          _pushNotificationService.registerForUser(user.uid);
        } else {
          _pushNotificationService.clearCurrentUser();
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final emailVerificationStatus = ref.watch(emailVerificationStatusProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return emailVerificationStatus.when(
            data: (isVerified) {
              if (!isVerified) {
                return const EmailVerificationPendingView(autoSendOnLoad: false);
              }
              return const MainNavigationView();
            },
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const EmailVerificationPendingView(autoSendOnLoad: false),
          );
        } else {
          debugPrint('AuthWrapper: User not logged in, showing MainNavigationView');
          return const MainNavigationView();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // エラーが発生した場合はホーム画面に戻る
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
                child: const Text('ホームに戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
