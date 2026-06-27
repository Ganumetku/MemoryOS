import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures in the application.
/// Failures are returned from repositories to use cases.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Represents failures that occur during server/network request handling.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Represents failures related to local cache or device storage operations.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Represents failures due to absence of internet connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Represents database failures for offline storage.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Represents authentication specific failures.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Represents AI-related errors.
class AIEngineFailure extends Failure {
  const AIEngineFailure(super.message, {super.code});
}
