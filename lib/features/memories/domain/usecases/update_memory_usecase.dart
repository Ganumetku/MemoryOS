import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class UpdateMemoryUseCase implements UseCase<void, Memory> {
  final MemoryRepository repository;

  UpdateMemoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Memory memory) async {
    return await repository.updateMemory(memory);
  }
}
