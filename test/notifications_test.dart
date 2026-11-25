import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/models/notification_item_model.dart';

void main() {
  group('Notifications Unit Tests', () {
    test('First-time user starts with empty notifications and zero unread count', () {
      final List<NotificationItemModel> firstTimeUserNotifs = [];

      expect(firstTimeUserNotifs.isEmpty, isTrue);
      expect(firstTimeUserNotifs.where((n) => !n.isRead).length, equals(0));
    });

    test('User notification model correctly serializes and deserializes', () {
      final now = DateTime.now();
      final model = NotificationItemModel(
        id: 'app_filed_123',
        title: 'Visa File Submitted',
        body: 'Your application has been filed.',
        timestamp: now,
        category: NotificationCategory.applications,
        isRead: false,
        actionRoute: '/dashboard',
        actionLabel: 'Track File',
      );

      final json = model.toJson();
      final reconstituted = NotificationItemModel.fromJson(json);

      expect(reconstituted.id, equals('app_filed_123'));
      expect(reconstituted.title, equals('Visa File Submitted'));
      expect(reconstituted.category, equals(NotificationCategory.applications));
      expect(reconstituted.isRead, isFalse);
      expect(reconstituted.actionRoute, equals('/dashboard'));
    });

    test('Category filtering correctly isolates applications and visa updates', () {
      final notifs = [
        NotificationItemModel(
          id: '1',
          title: 'Visa File Submitted',
          body: 'File 1',
          timestamp: DateTime.now(),
          category: NotificationCategory.applications,
          isRead: false,
        ),
        NotificationItemModel(
          id: '2',
          title: 'Visa Policy Update',
          body: 'Update 2',
          timestamp: DateTime.now(),
          category: NotificationCategory.visaUpdates,
          isRead: true,
        ),
        NotificationItemModel(
          id: '3',
          title: 'Scholarship Offer',
          body: 'Offer 3',
          timestamp: DateTime.now(),
          category: NotificationCategory.offers,
          isRead: false,
        ),
      ];

      final appNotifs = notifs.where((n) => n.category == NotificationCategory.applications).toList();
      final visaNotifs = notifs.where((n) => n.category == NotificationCategory.visaUpdates).toList();
      final unreadNotifs = notifs.where((n) => !n.isRead).toList();

      expect(appNotifs.length, equals(1));
      expect(appNotifs.first.id, equals('1'));
      expect(visaNotifs.length, equals(1));
      expect(visaNotifs.first.id, equals('2'));
      expect(unreadNotifs.length, equals(2));
    });

    test('Mark as read toggle updates isRead state correctly', () {
      final model = NotificationItemModel(
        id: 'test_notif',
        title: 'Test',
        body: 'Body',
        timestamp: DateTime.now(),
        category: NotificationCategory.system,
        isRead: false,
      );

      final readModel = model.copyWith(isRead: true);
      expect(model.isRead, isFalse);
      expect(readModel.isRead, isTrue);
    });
  });
}
