import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../services/logging_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/validate_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/delete_user_usecase.dart';
import '../../features/auth/domain/usecases/get_user_details_usecase.dart';
import '../../features/auth/domain/usecases/get_all_music_usecase.dart';
import '../../features/auth/domain/usecases/social_login_usecase.dart';
import '../../features/auth/domain/usecases/create_profile_usecase.dart';
import '../../features/auth/presentation/viewmodels/terms_and_conditions_viewmodel.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Core
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => LoggingService());
  
  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sharedPreferences: sl()),
  );
  
  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => ValidateOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserUseCase(sl()));
  sl.registerLazySingleton(() => GetUserDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllMusicUseCase(sl()));
  sl.registerLazySingleton(() => SocialLoginUseCase(sl()));
  sl.registerLazySingleton(() => CreateProfileUseCase(sl()));
  
  // Auth ViewModels
  sl.registerFactory(() => TermsAndConditionsViewModel());
}