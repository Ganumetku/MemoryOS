import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/memory.dart';
import '../../domain/repositories/memory_repository.dart';
import '../datasources/memory_local_datasource.dart';
import '../models/memory_model.dart';

/// Concrete implementation of [MemoryRepository] coordinating with local storage.
class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryLocalDataSource localDataSource;

  MemoryRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Memory>>> getMemories() async {
    try {
      final models = await localDataSource.getMemories();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to load memories from local vault: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveMemory(Memory memory) async {
    try {
      final model = MemoryModel.fromEntity(memory);
      await localDataSource.saveMemory(model);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to secure memory in local vault: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateMemory(Memory memory) async {
    try {
      final model = MemoryModel.fromEntity(memory);
      await localDataSource.updateMemory(model);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to update memory in local vault: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteMemory(int id) async {
    try {
      await localDataSource.deleteMemory(id);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to erase memory from local vault: $e'),
      );
    }
  }
}
