import 'package:dartz/dartz.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/device_mapping_request.dart';
import '../../domain/entities/device_mapping_response.dart';
import '../../domain/repositories/auth_repository.dart';

class MapDeviceWithoutOtpUseCase {
  final AuthRepository authRepository;

  MapDeviceWithoutOtpUseCase(this.authRepository);

  Future<Either<String, DeviceMappingResponse>> call(DeviceMappingRequest request) async {
    return await authRepository.mapDeviceWithoutOtp(request);
  }
}
