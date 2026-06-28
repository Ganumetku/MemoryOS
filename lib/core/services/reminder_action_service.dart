import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/memories/domain/entities/memory.dart';
import '../../features/memories/presentation/bloc/memory_cubit.dart';

class ReminderActionService {
  static void completeReminder(BuildContext context, Memory m) {
    context.read<MemoryCubit>().toggleReminderCompleted(m);
  }

  static void deleteReminder(BuildContext context, Memory m) {
    context.read<MemoryCubit>().removeMemory(m.id);
  }

  static Future<void> rescheduleReminder(BuildContext context, Memory m, DateTime newTime) async {
    await context.read<MemoryCubit>().rescheduleReminder(m, newTime);
  }
}
