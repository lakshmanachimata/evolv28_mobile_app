import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class DeleteUserUseCase {
  final AuthRepository repository;

  DeleteUserUseCase(this.repository);

  Future<Either<String, bool>> call() async {
    return await repository.deleteUserAccount();
  }
}
