import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';

class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _wellController = TextEditingController();
  final _improveController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _wellController.dispose();
    _improveController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = months[now.month - 1];
    final title = "Daily Reflection - ${now.day} $monthStr";

    final content = "What went well today?\n${_wellController.text.trim()}\n\nWhat can be better tomorrow?\n${_improveController.text.trim()}";

    try {
      final cubit = sl<MemoryCubit>();
      await cubit.addMemory(
        content,
        title: title,
        type: 'Reflection',
        tags: ['reflection'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Reflection saved. I'll remember this day.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.brandPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save reflection: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Reflection',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll20,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Take a moment to reflect on your day. This will be stored securely in your digital vault.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                AppSpacing.v24,

                // Question 1
                Text(
                  "What went well today?",
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.v8,
                MemoryTextField(
                  controller: _wellController,
                  hintText: "Reflect on positive events, achievements or moments...",
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please share what went well today";
                    }
                    return null;
                  },
                ),
                AppSpacing.v24,

                // Question 2
                Text(
                  "What can be better tomorrow?",
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.v8,
                MemoryTextField(
                  controller: _improveController,
                  hintText: "What could you do better or handle differently tomorrow?",
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please share what can be better tomorrow";
                    }
                    return null;
                  },
                ),
                AppSpacing.v32,

                MemoryPrimaryButton(
                  text: "Save Reflection",
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _saveReflection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
