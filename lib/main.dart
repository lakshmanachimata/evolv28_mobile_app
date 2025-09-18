import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/send_otp_usecase.dart';
import 'features/auth/domain/usecases/validate_otp_usecase.dart';
import 'features/auth/domain/usecases/delete_user_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await initializeDependencies();
  
  // Initialize API client
  sl<ApiClient>().initialize();
  await sl<ApiClient>().loadToken();
  
  runApp(const Evolv28App());
}

class Evolv28App extends StatelessWidget {
  const Evolv28App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LoginUseCase>(
          create: (_) => sl<LoginUseCase>(),
        ),
        Provider<SendOtpUseCase>(
          create: (_) => sl<SendOtpUseCase>(),
        ),
        Provider<ValidateOtpUseCase>(
          create: (_) => sl<ValidateOtpUseCase>(),
        ),
        Provider<AuthRepository>(
          create: (_) => sl<AuthRepository>(),
        ),
        Provider<DeleteUserUseCase>(
          create: (_) => sl<DeleteUserUseCase>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Evolv28',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Set status bar icons to black color
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
          );
          return child!;
        },
      ),
    );
  }
}
