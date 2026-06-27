import 'package:equatable/equatable.dart';

/// Base class for all states in the Capture screen flow.
abstract class CaptureState extends Equatable {
  const CaptureState();

  @override
  List<Object?> get props => [];
}

/// Inactive/Welcome page view state.
class CaptureInitial extends CaptureState {
  const CaptureInitial();
}

/// Simulated saving process state.
class CaptureLoading extends CaptureState {
  const CaptureLoading();
}

/// Saved successfully state holding the text fragment.
class CaptureSuccess extends CaptureState {
  final String capturedText;

  const CaptureSuccess(this.capturedText);

  @override
  List<Object?> get props => [capturedText];
}
