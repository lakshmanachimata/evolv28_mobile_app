import 'package:dartz/dartz.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/create_profile_request.dart';
import '../../domain/entities/create_profile_response.dart';
import '../../domain/repositories/auth_repository.dart';

class CreateProfileUseCase {
  final AuthRepository authRepository;

  CreateProfileUseCase(this.authRepository);

  Future<Either<String, CreateProfileResponse>> call(CreateProfileRequest request) async {
    return await authRepository.createProfile(request);
  }
}
