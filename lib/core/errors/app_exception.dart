/// Base exception for data-layer exceptions.
/// These should be caught at the repository level and converted to [Failure]s.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? " ($code)" : ""}';
}

/// Thrown during remote data retrieval errors (e.g. Supabase, Rest API).
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Thrown when local disk or cache access fails.
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Thrown when network connection is absent or timed out.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Thrown during local database engine operations (e.g. SQLite, Hive, Isar).
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

/// Thrown during authentication, authorization, or session management operations.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Thrown by the local or remote AI engine wrapper if execution fails.
class AIEngineException extends AppException {
  const AIEngineException(super.message, {super.code});
}
