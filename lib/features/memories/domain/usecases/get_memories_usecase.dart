import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class GetMemoriesUseCase implements UseCase<List<Memory>, NoParams> {
  final MemoryRepository repository;

  GetMemoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Memory>>> call(NoParams params) async {
    return await repository.getMemories();
  }
}
