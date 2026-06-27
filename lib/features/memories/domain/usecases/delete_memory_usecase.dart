import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/memory_repository.dart';

class DeleteMemoryUseCase implements UseCase<void, int> {
  final MemoryRepository repository;

  DeleteMemoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteMemory(id);
  }
}
