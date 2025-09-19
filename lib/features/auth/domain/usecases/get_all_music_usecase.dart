import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class GetAllMusicUseCase {
  final AuthRepository repository;

  GetAllMusicUseCase(this.repository);

  Future<Either<String, dynamic>> call(int userId) async {
    return await repository.getAllMusic(userId);
  }
}
