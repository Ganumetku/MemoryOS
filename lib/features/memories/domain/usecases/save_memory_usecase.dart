import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class SaveMemoryUseCase implements UseCase<void, Memory> {
  final MemoryRepository repository;

  SaveMemoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Memory memory) async {
    return await repository.saveMemory(memory);
  }
}
