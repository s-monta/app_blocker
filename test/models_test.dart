import 'package:app_blocker/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const app = InstalledApp(name: 'Sample', packageName: 'jp.example.sample');

  test('one-time rule blocks only inside its interval', () {
    final rule = BlockRule(
      name: 'Focus',
      mode: RuleMode.oneTime,
      startAt: DateTime(2026, 9, 21, 10),
      endAt: DateTime(2026, 9, 21, 11),
      apps: const [app],
    );
    expect(rule.isBlockingAt(DateTime(2026, 9, 21, 9, 59)), isFalse);
    expect(rule.isBlockingAt(DateTime(2026, 9, 21, 10, 30)), isTrue);
    expect(rule.isBlockingAt(DateTime(2026, 9, 21, 11)), isFalse);
  });

  test('daily rule respects weekday and time', () {
    final rule = BlockRule(
      name: 'Evening',
      mode: RuleMode.daily,
      startAt: DateTime(2026, 9, 1),
      endAt: DateTime(2026, 10, 1),
      startMinute: 22 * 60,
      endMinute: 23 * 60,
      daysMask: 1,
      apps: const [app],
    );
    expect(DateTime(2026, 9, 21).weekday, DateTime.monday);
    expect(rule.isBlockingAt(DateTime(2026, 9, 21, 22, 30)), isTrue);
    expect(rule.isBlockingAt(DateTime(2026, 9, 22, 22, 30)), isFalse);
  });
}
