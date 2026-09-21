import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database.dart';
import 'models.dart';
import 'platform_bridge.dart';

class CreateRulePage extends StatefulWidget {
  const CreateRulePage({super.key});

  @override
  State<CreateRulePage> createState() => _CreateRulePageState();
}

class _CreateRulePageState extends State<CreateRulePage> {
  final _nameController = TextEditingController();
  final List<InstalledApp> _selectedApps = [];
  RuleMode _mode = RuleMode.oneTime;
  late DateTime _start;
  late DateTime _end;
  TimeOfDay _dailyStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dailyEnd = const TimeOfDay(hour: 23, minute: 0);
  int _daysMask = 127;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = now;
    _end = now.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickApps() async {
    final result = await Navigator.of(context).push<List<InstalledApp>>(
      MaterialPageRoute(builder: (_) => AppPickerPage(initial: _selectedApps)),
    );
    if (result != null) {
      setState(
        () => _selectedApps
          ..clear()
          ..addAll(result),
      );
    }
  }

  Future<DateTime?> _dateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ja'),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: _day(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDateRange: DateTimeRange(start: _day(_start), end: _day(_end)),
      locale: const Locale('ja'),
    );
    if (range != null) {
      setState(() {
        _start = _day(range.start);
        _end = _day(range.end).add(const Duration(days: 1));
      });
    }
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String? _validationError() {
    if (_selectedApps.isEmpty) return 'ブロックするアプリを選んでください。';
    if (_mode == RuleMode.oneTime) {
      if (!_end.isAfter(_start)) return '終了は開始より後にしてください。';
      if (!_end.isAfter(DateTime.now())) return '終了時刻は未来にしてください。';
    } else {
      if (_daysMask == 0) return '曜日を1つ以上選んでください。';
      if (_minutes(_dailyEnd) <= _minutes(_dailyStart)) {
        return '終了時刻は開始時刻より後にしてください。';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validationError();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded),
        title: const Text('このルールを確定しますか？'),
        content: const Text(
          '開始後は、終了するまでアプリ内から変更・解除できません。日時と対象アプリをもう一度確認してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確定する'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    final defaultName = _mode == RuleMode.oneTime ? '集中タイム' : 'デイリーフォーカス';
    final rule = BlockRule(
      name: _nameController.text.trim().isEmpty
          ? defaultName
          : _nameController.text.trim(),
      mode: _mode,
      startAt: _mode == RuleMode.oneTime ? _start : _day(_start),
      endAt: _mode == RuleMode.oneTime ? _end : _day(_end),
      apps: List.unmodifiable(_selectedApps),
      startMinute: _mode == RuleMode.daily ? _minutes(_dailyStart) : null,
      endMinute: _mode == RuleMode.daily ? _minutes(_dailyEnd) : null,
      daysMask: _daysMask,
    );
    await AppDatabase.instance.insertRule(rule);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy/M/d (E)  HH:mm', 'ja_JP');
    return Scaffold(
      appBar: AppBar(title: const Text('新しいブロック')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          const _Label('ルール名'),
          TextField(
            controller: _nameController,
            maxLength: 30,
            decoration: const InputDecoration(
              hintText: '例：夜の読書時間',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          const _Label('ブロックするアプリ'),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _pickApps,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apps_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _selectedApps.isEmpty
                          ? 'アプリを選択'
                          : '${_selectedApps.length}個選択：${_selectedApps.take(2).map((e) => e.name).join('、')}${_selectedApps.length > 2 ? ' ほか' : ''}',
                      style: TextStyle(
                        fontWeight: _selectedApps.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _Label('タイミング'),
          SegmentedButton<RuleMode>(
            segments: const [
              ButtonSegment(
                value: RuleMode.oneTime,
                label: Text('1回だけ'),
                icon: Icon(Icons.timer_outlined),
              ),
              ButtonSegment(
                value: RuleMode.daily,
                label: Text('曜日で繰り返す'),
                icon: Icon(Icons.repeat_rounded),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) {
              setState(() {
                _mode = value.first;
                if (_mode == RuleMode.daily) {
                  _start = _day(DateTime.now());
                  _end = _start.add(const Duration(days: 30));
                }
              });
            },
          ),
          const SizedBox(height: 18),
          if (_mode == RuleMode.oneTime) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final preset in const [(1, '1時間'), (2, '2時間'), (8, '8時間')])
                  ActionChip(
                    label: Text('今から${preset.$2}'),
                    onPressed: () => setState(() {
                      _start = DateTime.now();
                      _end = _start.add(Duration(hours: preset.$1));
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _DateTile(
              label: '開始',
              value: format.format(_start),
              onTap: () async {
                final value = await _dateTime(_start);
                if (value != null) setState(() => _start = value);
              },
            ),
            const SizedBox(height: 8),
            _DateTile(
              label: '終了',
              value: format.format(_end),
              onTap: () async {
                final value = await _dateTime(_end);
                if (value != null) setState(() => _end = value);
              },
            ),
          ] else ...[
            _DateTile(
              label: '実施期間',
              value:
                  '${DateFormat('yyyy/M/d').format(_start)} 〜 ${DateFormat('yyyy/M/d').format(_end.subtract(const Duration(days: 1)))}',
              onTap: _pickDateRange,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: '毎日 開始',
                    value: _dailyStart,
                    onChanged: (v) => setState(() => _dailyStart = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeTile(
                    label: '終了',
                    value: _dailyEnd,
                    onChanged: (v) => setState(() => _dailyEnd = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(const ['月', '火', '水', '木', '金', '土', '日'][i]),
                    selected: (_daysMask & (1 << i)) != 0,
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _daysMask |= 1 << i;
                      } else {
                        _daysMask &= ~(1 << i);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFF9A4E28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '意志力に頼らないため、確定したルールは終了まで変更・削除できません。',
                    style: TextStyle(color: Color(0xFF713C25), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_rounded),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text('この内容でロックする'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Colors.white.withValues(alpha: .75),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    leading: const Icon(Icons.calendar_month_outlined),
    title: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Color(0xFF68726B)),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.edit_outlined, size: 19),
    onTap: onTap,
  );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () async {
      final picked = await showTimePicker(context: context, initialTime: value);
      if (picked != null) onChanged(picked);
    },
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF68726B)),
          ),
          const SizedBox(height: 4),
          Text(
            value.format(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class AppPickerPage extends StatefulWidget {
  const AppPickerPage({super.key, required this.initial});
  final List<InstalledApp> initial;
  @override
  State<AppPickerPage> createState() => _AppPickerPageState();
}

class _AppPickerPageState extends State<AppPickerPage> {
  List<InstalledApp>? _apps;
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.map((a) => a.packageName).toSet();
    PlatformBridge.installedApps().then((apps) {
      if (mounted) setState(() => _apps = apps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _apps
        ?.where(
          (a) =>
              a.name.toLowerCase().contains(_query.toLowerCase()) ||
              a.packageName.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリを選択'),
        actions: [
          TextButton(
            onPressed: _apps == null
                ? null
                : () => Navigator.pop(
                    context,
                    _apps!
                        .where((a) => _selected.contains(a.packageName))
                        .toList(),
                  ),
            child: Text('完了 (${_selected.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'アプリ名を検索',
              ),
            ),
          ),
          Expanded(
            child: visible == null
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? const Center(child: Text('該当するアプリがありません'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final app = visible[index];
                      final selected = _selected.contains(app.packageName);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            _selected.add(app.packageName);
                          } else {
                            _selected.remove(app.packageName);
                          }
                        }),
                        secondary: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Text(app.name.characters.first.toUpperCase()),
                        ),
                        title: Text(
                          app.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
