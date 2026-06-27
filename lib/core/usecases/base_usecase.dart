import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';

/// Contract for application business usecases.
/// Enforces a standardized execution pattern and proper error handling.
///
/// [T] is the returned data type on success.
/// [Params] is the input arguments required for the execution.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Helper class to represent use cases that do not require any input parameters.
class NoParams {
  const NoParams();
}
