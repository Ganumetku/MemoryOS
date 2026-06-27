import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Contract for checking network connectivity.
abstract class NetworkInfo {
  /// Emits `true` if internet connection is currently active, `false` otherwise.
  Future<bool> get isConnected;

  /// Stream to listen to real-time connection status changes.
  Stream<bool> get onConnectionChanged;
}

/// Implementation of [NetworkInfo] using the `internet_connection_checker` package.
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;

  @override
  Stream<bool> get onConnectionChanged => connectionChecker.onStatusChange.map(
    (status) => status == InternetConnectionStatus.connected,
  );
}
