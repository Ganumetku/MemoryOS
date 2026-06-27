import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/memory.dart';

/// Contract interface for the Memories data repository.
abstract class MemoryRepository {
  Future<Either<Failure, List<Memory>>> getMemories();
  Future<Either<Failure, void>> saveMemory(Memory memory);
  Future<Either<Failure, void>> updateMemory(Memory memory);
  Future<Either<Failure, void>> deleteMemory(int id);
}
