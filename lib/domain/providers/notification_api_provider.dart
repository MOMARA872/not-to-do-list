import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/notification_api.g.dart';

/// Pigeon channel singleton for the daily reminder schedule/cancel API.
/// Hand-written (no `@riverpod` codegen) to match the Phase 1 deviation note.
///
/// Tests override via:
/// `notificationApiProvider.overrideWith(
///   (ref) => MockNotificationApi(),
/// )`.
final Provider<NotificationApi> notificationApiProvider =
    Provider<NotificationApi>((ref) => NotificationApi());
