import 'package:isar/isar.dart';

part 'follow_up_model.g.dart';

@collection
class FollowUpModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late int memoryId;

  late String status; // 'pending', 'completed', 'dismissed', 'remind_later'
  late DateTime scheduledAt;
  late String question;
}
