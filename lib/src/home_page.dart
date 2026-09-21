import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'create_rule_page.dart';
import 'database.dart';
import 'models.dart';
import 'platform_bridge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<BlockRule> _rules = const [];
  bool _accessibilityEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final results = await Future.wait<Object>([
      AppDatabase.instance.getRules(),
      PlatformBridge.isAccessibilityEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _rules = results[0] as List<BlockRule>;
      _accessibilityEnabled = results[1] as bool;
      _loading = false;
    });
  }

  Future<void> _createRule() async {
    if (!_accessibilityEnabled) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.shield_outlined),
          title: const Text('先にブロック機能を有効にします'),
          content: const Text(
            'ルールを確実に実行するため、Androidのユーザー補助設定で「Focus Gate ブロック機能」を許可してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('あとで'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('設定を開く'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await PlatformBridge.openAccessibilitySettings();
      }
      return;
    }
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateRulePage()));
    if (created == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final active = _rules.where((r) => !r.hasExpired).toList();
    final past = _rules.where((r) => r.hasExpired).toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FOCUS GATE',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '時間を、取り戻す。',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRule,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ブロックを設定'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                children: [
                  _ServiceCard(
                    enabled: _accessibilityEnabled,
                    onTap: PlatformBridge.openAccessibilitySettings,
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(title: '設定中', count: active.length),
                  const SizedBox(height: 12),
                  if (active.isEmpty)
                    const _EmptyCard()
                  else
                    ...active.map((rule) => _RuleCard(rule: rule)),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionTitle(title: '終了済み', count: past.length),
                    const SizedBox(height: 12),
                    ...past.map((rule) => _RuleCard(rule: rule, dimmed: true)),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'ルールは端末内のSQLiteに保存されます。アプリを更新しても設定は引き継がれます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF68726B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF3F6B4F) : const Color(0xFFC66A3D);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  enabled ? Icons.shield_rounded : Icons.shield_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'ブロック機能は有効です' : '初回設定が必要です',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled ? 'タップして端末設定を確認' : 'タップして「Focus Gate」を許可',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE1E8E1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Column(
        children: [
          Icon(
            Icons.spa_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'まだルールはありません',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            '集中したい時間をひとつ決めてみましょう',
            style: TextStyle(color: Color(0xFF68726B)),
          ),
        ],
      ),
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, this.dimmed = false});
  final BlockRule rule;
  final bool dimmed;

  String _schedule() {
    if (rule.mode == RuleMode.oneTime) {
      final format = DateFormat('M/d (E) HH:mm', 'ja_JP');
      return '${format.format(rule.startAt)}  →  ${format.format(rule.endAt)}';
    }
    final date = DateFormat('M/d', 'ja_JP');
    final start = _minute(rule.startMinute!);
    final end = _minute(rule.endMinute!);
    const names = ['月', '火', '水', '木', '金', '土', '日'];
    final days = [
      for (var i = 0; i < 7; i++)
        if ((rule.daysMask & (1 << i)) != 0) names[i],
    ].join('・');
    return '${date.format(rule.startAt)}〜${date.format(rule.endAt.subtract(const Duration(days: 1)))}  $start–$end\n$days';
  }

  String _minute(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dimmed ? .55 : 1,
    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dimmed ? Colors.grey : const Color(0xFF5B8668),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rule.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  dimmed ? Icons.check_rounded : Icons.lock_outline_rounded,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _schedule(),
              style: const TextStyle(height: 1.55, color: Color(0xFF526058)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: rule.apps
                  .map(
                    (app) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9ECE6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        app.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
