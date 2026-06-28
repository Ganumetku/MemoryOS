import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../bloc/capture_cubit.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  completed,
  error,
}

/// Screen 013 - Voice Capture Page.
/// Renders a premium radar pulsating mic orb and live wave visualizer for offline speech recognition.
class VoiceCapturePage extends StatelessWidget {
  const VoiceCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CaptureCubit(),
      child: const _VoiceCaptureView(),
    );
  }
}

class _VoiceCaptureView extends StatefulWidget {
  const _VoiceCaptureView();

  @override
  State<_VoiceCaptureView> createState() => _VoiceCaptureViewState();
}

class _VoiceCaptureViewState extends State<_VoiceCaptureView>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasFinalResult = false;
  bool _isDisposed = false;
  VoiceState _voiceState = VoiceState.idle;

  String _recognizedText = '';
  double _soundLevel = 0.0;
  String _statusText = 'Initializing assistant...';

  late AnimationController _pulseController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _speech = stt.SpeechToText();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    _speech.stop();
    _speech.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final hasMicPermission = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = hasMicPermission;
          if (hasMicPermission) {
            _startListening();
          } else {
            _voiceState = VoiceState.error;
            _statusText = 'Microphone permission denied';
          }
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = false;
          _voiceState = VoiceState.error;
          _statusText = 'Speech recognition unavailable';
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('[VoiceCapture] onStatus: $status, current state: $_voiceState');
    if (_isDisposed) return;

    if (status == 'listening') {
      if (mounted && !_isDisposed) {
        setState(() {
          _isListening = true;
          _voiceState = VoiceState.listening;
          _statusText = 'Listening...';
        });
      }
    } else if (status == 'done' || status == 'notListening') {
      if (mounted && !_isDisposed) {
        setState(() {
          _isListening = false;
          final transcript = _textController.text.trim();
          if (transcript.isNotEmpty) {
            _voiceState = VoiceState.completed;
            _statusText = 'Ready to remember';
          } else {
            _voiceState = VoiceState.error;
            _statusText = "I couldn't hear anything. Try speaking again.";
          }
        });
      }
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('[VoiceCapture] onError: $error');
    if (mounted && !_isDisposed) {
      setState(() {
        _isListening = false;
        _voiceState = VoiceState.error;
        _statusText = "I couldn't hear anything. Try speaking again.";
      });
    }
  }

  Future<void> _startListening() async {
    debugPrint('[VoiceCapture] startListening called');
    if (_isDisposed) return;
    if (!_isInitialized) {
      await _initSpeech();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _recognizedText = '';
      _textController.text = '';
      _soundLevel = 0.0;
      _isListening = true;
      _hasFinalResult = false;
      _voiceState = VoiceState.listening;
      _statusText = 'Listening...';
    });

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: (level) {
          if (mounted && !_isDisposed) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('[VoiceCapture] listen error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isListening = false;
          _voiceState = VoiceState.error;
          _statusText = 'Speech session failed';
        });
      }
    }
  }

  void _handleSpeechResult(dynamic result) {
    debugPrint('[VoiceCapture] onResult partial/final: final=${result.finalResult}, words=${result.recognizedWords}');
    if (_isDisposed) return;
    if (_hasFinalResult) return;

    if (mounted && !_isDisposed) {
      setState(() {
        _recognizedText = result.recognizedWords;
        _textController.text = result.recognizedWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    }

    if (result.finalResult == true) {
      _hasFinalResult = true;
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    debugPrint('[VoiceCapture] stopListening called');
    HapticFeedback.mediumImpact();
    await _speech.stop();
    if (mounted && !_isDisposed) {
      setState(() {
        _isListening = false;
        final transcript = _textController.text.trim();
        if (transcript.isNotEmpty) {
          _voiceState = VoiceState.completed;
          _statusText = 'Ready to remember';
        } else {
          _voiceState = VoiceState.error;
          _statusText = "I couldn't hear anything. Try speaking again.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[VoiceCapture] current voice state: $_voiceState');
    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDarkSecondary,
            size: 20,
          ),
          onPressed: () {
            if (_isListening) {
              _speech.stop();
            }
            context.pop();
          },
        ),
        title: Text(
          'Voice Assistant',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Pulse radar + Microphone orb representation
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsating Circle 1
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final value = _pulseController.value;
                        final scale = 1.0 + (value * 0.8);
                        final opacity = _isListening ? (0.3 * (1.0 - value)) : 0.0;
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Outer Pulsating Circle 2 (Staggered)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final value = (_pulseController.value + 0.5) % 1.0;
                        final scale = 1.0 + (value * 0.8);
                        final opacity = _isListening ? (0.3 * (1.0 - value)) : 0.0;
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Primary Hero Trigger Button
                    GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                      child: Hero(
                        tag: 'voice_speak_hero',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.brandPrimary,
                                  AppColors.brandSecondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withAlpha(80),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Waveform Visualizer
              Center(
                child: _WaveformWidget(
                  soundLevel: _soundLevel,
                  isListening: _isListening,
                ),
              ),

              const SizedBox(height: 32),

              // Listening / Assistant Status text
              Center(
                child: Text(
                  _statusText,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: _voiceState == VoiceState.error ? AppColors.error : AppColors.textDarkSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Large box for live recognized text transcript (editable)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgDarkSecondary.withAlpha(128),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.bgDarkTertiary.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontSize: 18,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _isListening ? 'Speak now, I\'m transcribing...' : 'Tap mic to start speaking...',
                      hintStyle: const TextStyle(
                        color: AppColors.textDarkTertiary,
                        fontSize: 18,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _recognizedText = val;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Action Buttons
              if (!_isListening) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _textController.clear();
                          setState(() {
                            _recognizedText = '';
                            _voiceState = VoiceState.idle;
                            _hasFinalResult = false;
                          });
                          _startListening();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.bgDarkTertiary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textDarkSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _textController.text.trim().isNotEmpty
                            ? () {
                                HapticFeedback.lightImpact();
                                context.pop(_textController.text.trim());
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          disabledBackgroundColor: AppColors.bgDarkTertiary.withAlpha(100),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Use This Memory',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: _recognizedText.trim().isNotEmpty
                                ? Colors.white
                                : AppColors.textDarkTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Spacer matching buttons height to avoid layout shift!
                const SizedBox(height: 52),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformWidget extends StatelessWidget {
  final double soundLevel;
  final bool isListening;

  const _WaveformWidget({
    required this.soundLevel,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (soundLevel + 2.0).clamp(0.0, 16.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final baseHeight = [12.0, 24.0, 36.0, 48.0, 36.0, 24.0, 12.0][index];
        final height = isListening
            ? baseHeight + (normalized * (index % 2 == 0 ? 1.5 : 2.5))
            : baseHeight;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 4,
          height: height.clamp(4.0, 72.0),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isListening
                ? AppColors.brandPrimary.withAlpha((255 - (index * 20)).round().clamp(100, 255))
                : AppColors.bgDarkTertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
