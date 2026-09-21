class InstalledApp {
  const InstalledApp({required this.name, required this.packageName});

  final String name;
  final String packageName;

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    name: map['name']! as String,
    packageName: map['packageName']! as String,
  );
}

enum RuleMode { oneTime, daily }

class BlockRule {
  const BlockRule({
    this.id,
    required this.name,
    required this.mode,
    required this.startAt,
    required this.endAt,
    required this.apps,
    this.startMinute,
    this.endMinute,
    this.daysMask = 127,
  });

  final int? id;
  final String name;
  final RuleMode mode;
  final DateTime startAt;
  final DateTime endAt;
  final List<InstalledApp> apps;
  final int? startMinute;
  final int? endMinute;
  final int daysMask;

  bool get hasExpired => !DateTime.now().isBefore(endAt);

  bool isBlockingAt(DateTime now) {
    if (now.isBefore(startAt) || !now.isBefore(endAt)) return false;
    if (mode == RuleMode.oneTime) return true;
    final bit = 1 << (now.weekday - 1);
    if ((daysMask & bit) == 0) return false;
    final minute = now.hour * 60 + now.minute;
    return minute >= startMinute! && minute < endMinute!;
  }
}
