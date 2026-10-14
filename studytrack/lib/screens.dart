import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';
import 'i18n.dart';
import 'state.dart';

const kIcons = [Icons.calculate, Icons.science, Icons.translate, Icons.code, Icons.menu_book, Icons.palette, Icons.history_edu, Icons.public];
const kColors = [0xFF4F46E5, 0xFF14B8A6, 0xFFF59E0B, 0xFFEC4899, 0xFF22C55E, 0xFFEF4444, 0xFF0EA5E9, 0xFF8B5CF6];
const kPrimary = Color(0xFF4F46E5);

Widget card(BuildContext c, Widget child, {EdgeInsets p = const EdgeInsets.all(16)}) => Container(
      padding: p, margin: const EdgeInsets.only(bottom: 14), width: double.infinity,
      decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))]),
      child: child);
Widget h(BuildContext c, String s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(s, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)));
Widget muted(BuildContext c, String s) => Text(s, style: TextStyle(color: Theme.of(c).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13));
Future<bool> confirm(BuildContext c) async {
  final l = app.l;
  return await showDialog<bool>(context: c, builder: (_) => AlertDialog(content: Text(l.t('confirmDel')), actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.t('cancel'))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.t('delete'))),
      ])) ?? false;
}
Widget empty(BuildContext c) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Column(children: [
      const Icon(Icons.insights_outlined, size: 40, color: Color(0xFF94A3B8)), const SizedBox(height: 8), muted(c, app.l.t('noData'))])));
void go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

// ------------------------------------------------------------------ shell
class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (c, _) {
        final l = app.l;
        return Scaffold(
          body: SafeArea(child: [const HomePage(), const HistoryPage(), const AnalyticsPage(), const SettingsPage()][i]),
          floatingActionButton: FloatingActionButton(onPressed: () => go(c, const AddSession()), child: const Icon(Icons.add)),
          bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.t('home')),
            NavigationDestination(icon: const Icon(Icons.history), label: l.t('history')),
            NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: l.t('analytics')),
            NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.t('settings')),
          ]),
        );
      });
}

// ------------------------------------------------------------------ chart
class BarCard extends StatelessWidget {
  final List<String> labels; final List<int> mins; final Color color;
  const BarCard(this.labels, this.mins, {super.key, this.color = kPrimary});
  @override
  Widget build(BuildContext context) {
    final l = app.l;
    if (mins.every((m) => m == 0)) return empty(context);
    final mx = mins.reduce((a, b) => a > b ? a : b) / 60.0;
    return SizedBox(height: 190, child: BarChart(BarChartData(
      maxY: mx * 1.15, gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, m) {
          final i = v.toInt();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(i >= 0 && i < labels.length ? labels[i] : '', style: const TextStyle(fontSize: 10)));
        })),
      ),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, gi, r, ri) =>
          BarTooltipItem(l.dur(mins[gi]), const TextStyle(color: Colors.white, fontSize: 12)))),
      barGroups: [for (var i = 0; i < mins.length; i++) BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: mins[i] / 60.0, color: color, width: mins.length > 12 ? 6 : 16, borderRadius: BorderRadius.circular(4))])],
    )));
  }
}

// ------------------------------------------------------------------ home
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c) {
    final l = app.l, now = DateTime.now(), today = app.minutesOn(now);
    final recent = <int>[]; for (final s in app.sessions) { if (!recent.contains(s.subjectId) && recent.length < 4) recent.add(s.subjectId!); }
    final b = app.buckets('week');
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.t('hello'), style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      muted(c, l.longDate(now)), const SizedBox(height: 16),
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        muted(c, l.t('today')), Text(l.dur(today), style: Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (today / app.dailyGoal).clamp(0, 1).toDouble(), minHeight: 10, color: const Color(0xFF14B8A6))),
        const SizedBox(height: 6), muted(c, '${l.t('goal')}: ${l.dur(app.dailyGoal)}'),
      ])),
      const TimerCard(),
      if (recent.isNotEmpty) ...[h(c, l.t('recent')), Wrap(spacing: 8, children: [for (final id in recent) if (app.sub(id) != null)
        ActionChip(avatar: Icon(kIcons[app.sub(id)!.icon % kIcons.length], size: 16, color: Color(app.sub(id)!.color)), label: Text(app.sub(id)!.name), onPressed: () => go(c, AddSession(subjectId: id)))]), const SizedBox(height: 14)],
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h(c, '${l.t('week')} · ${l.dur(app.weekMinutes(now))}'), BarCard(b.$1, b.$2)])),
      OutlinedButton.icon(onPressed: () => go(c, const AddSession()), icon: const Icon(Icons.edit_calendar), label: Text(l.t('addSession'))),
      const SizedBox(height: 80),
    ]);
  }
}

class TimerCard extends StatefulWidget { const TimerCard({super.key}); @override State<TimerCard> createState() => _TimerCardState(); }
class _TimerCardState extends State<TimerCard> {
  Timer? t;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(seconds: 1), (_) { if (app.tRunning && mounted) setState(() {}); }); }
  @override void dispose() { t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final l = app.l, e = app.elapsed;
    app.tSubject ??= app.subjects.isEmpty ? null : app.subjects.first.id;
    if (app.sub(app.tSubject) == null) app.tSubject = app.subjects.isEmpty ? null : app.subjects.first.id;
    return card(c, Column(children: [
      if (app.subjects.isEmpty) muted(c, l.t('noSubjects')) else DropdownButton<int>(isExpanded: true, value: app.tSubject, underline: const SizedBox(),
        items: [for (final s in app.subjects) DropdownMenuItem(value: s.id, child: Text(s.name))],
        onChanged: app.timerActive ? null : (v) => setState(() => app.tSubject = v)),
      Text(l.n('${(e ~/ 3600).toString().padLeft(2, '0')}:${((e % 3600) ~/ 60).toString().padLeft(2, '0')}:${(e % 60).toString().padLeft(2, '0')}'),
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        if (!app.timerActive) FilledButton.icon(onPressed: app.tSubject == null ? null : () { app.timerStart(); setState(() {}); }, icon: const Icon(Icons.play_arrow), label: Text(l.t('start'))),
        if (app.timerActive && app.tRunning) FilledButton.tonalIcon(onPressed: () { app.timerPause(); setState(() {}); }, icon: const Icon(Icons.pause), label: Text(l.t('pause'))),
        if (app.timerActive && !app.tRunning) FilledButton.tonalIcon(onPressed: () { app.timerResume(); setState(() {}); }, icon: const Icon(Icons.play_arrow), label: Text(l.t('resume'))),
        if (app.timerActive) FilledButton.icon(onPressed: () async { await app.timerFinish(); if (mounted) setState(() {}); }, icon: const Icon(Icons.stop), label: Text(l.t('finish'))),
      ]),
    ]));
  }
}

// ------------------------------------------------------------------ history
class HistoryPage extends StatefulWidget { const HistoryPage({super.key}); @override State<HistoryPage> createState() => _HistoryState(); }
class _HistoryState extends State<HistoryPage> {
  String q = ''; int? sid; int minLen = 0; DateTimeRange? range;
  @override
  Widget build(BuildContext c) {
    final l = app.l;
    final list = app.sessions.where((s) {
      final sn = app.sub(s.subjectId)?.name ?? '';
      if (q.isNotEmpty && !(s.title.toLowerCase().contains(q.toLowerCase()) || sn.toLowerCase().contains(q.toLowerCase()))) return false;
      if (sid != null && s.subjectId != sid) return false;
      if (s.minutes < minLen) return false;
      if (range != null && (s.start.isBefore(range!.start) || s.start.isAfter(range!.end.add(const Duration(days: 1))))) return false;
      return true;
    }).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(decoration: InputDecoration(hintText: l.t('search'), prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), onChanged: (v) => setState(() => q = v)),
      const SizedBox(height: 8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        DropdownButton<int?>(value: sid, hint: Text(l.t('subject')), underline: const SizedBox(), items: [
          DropdownMenuItem<int?>(value: null, child: Text(l.t('all'))), for (final s in app.subjects) DropdownMenuItem<int?>(value: s.id, child: Text(s.name))], onChanged: (v) => setState(() => sid = v)),
        const SizedBox(width: 8),
        for (final m in [0, 30, 60]) Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: ChoiceChip(label: Text(m == 0 ? l.t('all') : l.t('min$m')), selected: minLen == m, onSelected: (_) => setState(() => minLen = m))),
        IconButton(icon: Icon(Icons.date_range, color: range == null ? null : kPrimary), onPressed: () async {
          final r = await showDateRangePicker(context: c, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
          setState(() => range = r);
        }),
        if (range != null) IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => range = null)),
      ])),
      if (list.isEmpty) empty(c),
      for (final s in list) card(c, p: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), ListTile(
        onTap: () => go(c, AddSession(edit: s)),
        leading: CircleAvatar(backgroundColor: Color(app.sub(s.subjectId)?.color ?? 0xFF64748B).withAlpha(40), child: Icon(kIcons[(app.sub(s.subjectId)?.icon ?? 0) % kIcons.length], color: Color(app.sub(s.subjectId)?.color ?? 0xFF64748B))),
        title: Text(s.title.isEmpty ? (app.sub(s.subjectId)?.name ?? '') : s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${l.date(s.start)}  ${l.hm(s.start)}–${l.hm(s.end)}${s.notes.isEmpty ? '' : '\n${s.notes}'}', maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.dur(s.minutes), style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirm(c)) await app.delSession(s.id!); })]),
      )),
      const SizedBox(height: 80),
    ]);
  }
}

// ------------------------------------------------------------------ analytics
class AnalyticsPage extends StatefulWidget { const AnalyticsPage({super.key}); @override State<AnalyticsPage> createState() => _AnalyticsState(); }
class _AnalyticsState extends State<AnalyticsPage> {
  String period = 'week';
  Widget stat(BuildContext c, String k, String v) => Expanded(child: card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [muted(c, k), const SizedBox(height: 4), Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]), p: const EdgeInsets.all(12)));
  @override
  Widget build(BuildContext c) {
    final l = app.l, now = DateTime.now(), ss = app.sessions;
    final total = ss.fold<int>(0, (a, s) => a + s.minutes), pd = app.perDay();
    final longest = ss.isEmpty ? 0 : ss.map((s) => s.minutes).reduce((a, b) => a > b ? a : b);
    final avg = pd.isEmpty ? 0 : total ~/ pd.length;
    final b = app.buckets(period);
    final tw = app.weekMinutes(now), lw = app.weekMinutes(now.subtract(const Duration(days: 7))), mxw = [tw, lw, 1].reduce((a, b) => a > b ? a : b);
    final bySub = <int, int>{}; for (final s in ss) { bySub[s.subjectId!] = (bySub[s.subjectId!] ?? 0) + s.minutes; }
    final byWd = <int, int>{}; pd.forEach((d, m) => byWd[d.weekday] = (byWd[d.weekday] ?? 0) + m);
    final best = byWd.isEmpty ? null : byWd.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    if (ss.isEmpty) return ListView(padding: const EdgeInsets.all(16), children: [empty(c)]);
    return ListView(padding: const EdgeInsets.all(16), children: [
      SegmentedButton<String>(showSelectedIcon: false, selected: {period}, onSelectionChanged: (v) => setState(() => period = v.first),
        segments: [for (final p in ['day', 'week', 'month', 'year']) ButtonSegment(value: p, label: Text(l.t(p)))]),
      const SizedBox(height: 14),
      card(c, BarCard(b.$1, b.$2)),
      Row(children: [stat(c, l.t('total'), l.dur(total)), const SizedBox(width: 10), stat(c, l.t('sessions'), l.n(ss.length))]),
      Row(children: [stat(c, l.t('avg'), l.dur(avg)), const SizedBox(width: 10), stat(c, l.t('longest'), l.dur(longest))]),
      Row(children: [stat(c, l.t('streak'), l.n(app.streak)), const SizedBox(width: 10), stat(c, l.t('bestDay'), best == null ? '-' : l.wd(DateTime(2024, 1, best)))]),
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h(c, l.t('share')),
        SizedBox(height: 170, child: PieChart(PieChartData(centerSpaceRadius: 46, sectionsSpace: 2, sections: [for (final e in bySub.entries)
          PieChartSectionData(value: e.value.toDouble(), color: Color(app.sub(e.key)?.color ?? 0xFF64748B), radius: 26, showTitle: false)]))),
        const SizedBox(height: 10),
        for (final e in (bySub.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(children: [
          Row(children: [CircleAvatar(radius: 5, backgroundColor: Color(app.sub(e.key)?.color ?? 0xFF64748B)), const SizedBox(width: 8), Expanded(child: Text(app.sub(e.key)?.name ?? '?')),
            Text('${l.dur(e.value)} · ${l.n((e.value * 100 / total).round())}%')]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: e.value / total, minHeight: 6, color: Color(app.sub(e.key)?.color ?? 0xFF64748B))),
        ])),
      ])),
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h(c, l.t('vs')),
        Text('${l.t('thisWeek')}: ${l.dur(tw)}'), LinearProgressIndicator(value: tw / mxw, minHeight: 8, color: kPrimary), const SizedBox(height: 10),
        Text('${l.t('lastWeek')}: ${l.dur(lw)}'), LinearProgressIndicator(value: lw / mxw, minHeight: 8, color: const Color(0xFF94A3B8))])),
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h(c, l.t('goalRate')),
        Text('${l.t('daily')}: ${l.n((app.minutesOn(now) * 100 / app.dailyGoal).round())}%'), LinearProgressIndicator(value: (app.minutesOn(now) / app.dailyGoal).clamp(0, 1).toDouble(), minHeight: 8, color: const Color(0xFF14B8A6)), const SizedBox(height: 10),
        Text('${l.t('weekly')}: ${l.n((tw * 100 / app.weeklyGoal).round())}%'), LinearProgressIndicator(value: (tw / app.weeklyGoal).clamp(0, 1).toDouble(), minHeight: 8, color: const Color(0xFFF59E0B))])),
    ]);
  }
}

// ------------------------------------------------------------------ settings & subjects
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  Future<void> goalDialog(BuildContext c, String key, int cur, void Function(int) set) async {
    final l = app.l, ctl = TextEditingController(text: '$cur');
    final ok = await showDialog<bool>(context: c, builder: (_) => AlertDialog(title: Text(l.t(key)), content: TextField(controller: ctl, keyboardType: TextInputType.number),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.t('cancel'))), TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.t('save')))]));
    final v = int.tryParse(toLatin(ctl.text.trim()));
    if (ok == true && v != null && v > 0) app.pref(() => set(v));
  }
  @override
  Widget build(BuildContext c) {
    final l = app.l;
    return ListView(padding: const EdgeInsets.all(16), children: [
      card(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h(c, l.t('language')),
        SegmentedButton<String>(showSelectedIcon: false, selected: {app.lang}, onSelectionChanged: (v) => app.pref(() { app.lang = v.first; app.jalali = v.first == 'fa'; }),
          segments: const [ButtonSegment(value: 'fa', label: Text('فارسی')), ButtonSegment(value: 'en', label: Text('English'))])])),
      card(c, p: EdgeInsets.zero, Column(children: [
        SwitchListTile(title: Text(l.t('dark')), value: app.dark, onChanged: (v) => app.pref(() => app.dark = v)),
        SwitchListTile(title: Text(l.t('jalali')), value: app.jalali, onChanged: (v) => app.pref(() => app.jalali = v)),
        SwitchListTile(title: Text(l.t('digits')), value: app.faDigits, onChanged: (v) => app.pref(() => app.faDigits = v)),
        ListTile(title: Text(l.t('dailyGoal')), trailing: Text(l.n(app.dailyGoal)), onTap: () => goalDialog(c, 'dailyGoal', app.dailyGoal, (v) => app.dailyGoal = v)),
        ListTile(title: Text(l.t('weeklyGoal')), trailing: Text(l.n(app.weeklyGoal)), onTap: () => goalDialog(c, 'weeklyGoal', app.weeklyGoal, (v) => app.weeklyGoal = v)),
      ])),
      card(c, p: EdgeInsets.zero, Column(children: [
        ListTile(leading: const Icon(Icons.collections_bookmark_outlined), title: Text(l.t('manage')), onTap: () => go(c, const SubjectsPage())),
        ListTile(leading: const Icon(Icons.copy_all_outlined), title: Text(l.t('export')), onTap: () async {
          await Clipboard.setData(ClipboardData(text: app.export()));
          if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.t('copied'))));
        }),
        ListTile(leading: const Icon(Icons.cleaning_services_outlined), title: Text(l.t('demoRemove')), onTap: () async { if (await confirm(c)) await app.clearDemo(); }),
      ])),
    ]);
  }
}

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: app, builder: (c, _) {
        final l = app.l;
        return Scaffold(
          appBar: AppBar(title: Text(l.t('subjects'))),
          floatingActionButton: FloatingActionButton(onPressed: () => subjectDialog(c), child: const Icon(Icons.add)),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            if (app.subjects.isEmpty) empty(c),
            for (final s in app.subjects) Builder(builder: (_) {
              final mine = app.sessions.where((x) => x.subjectId == s.id), tot = mine.fold<int>(0, (a, x) => a + x.minutes);
              return card(c, p: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), ListTile(
                onTap: () => subjectDialog(c, s),
                leading: CircleAvatar(backgroundColor: Color(s.color).withAlpha(40), child: Icon(kIcons[s.icon % kIcons.length], color: Color(s.color))),
                title: Text(s.name), subtitle: Text('${s.desc.isEmpty ? '' : '${s.desc}\n'}${l.dur(tot)} · ${l.n(mine.length)} ${l.t('sessions')}'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirm(c)) await app.delSubject(s.id!); }),
              ));
            }),
          ]),
        );
      });
}

Future<int?> subjectDialog(BuildContext c, [Subject? s]) async {
  final l = app.l, name = TextEditingController(text: s?.name), desc = TextEditingController(text: s?.desc);
  var col = s?.color ?? kColors[0], ic = s?.icon ?? 0;
  return showDialog<int>(context: c, builder: (dc) => StatefulBuilder(builder: (_, set) => AlertDialog(
        title: Text(s == null ? l.t('newSubject') : l.t('edit')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: l.t('name'))),
          TextField(controller: desc, maxLines: 2, decoration: InputDecoration(labelText: l.t('desc'))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [for (final k in kColors) GestureDetector(onTap: () => set(() => col = k), child: CircleAvatar(radius: 14, backgroundColor: Color(k), child: col == k ? const Icon(Icons.check, size: 16, color: Colors.white) : null))]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, children: [for (var i = 0; i < kIcons.length; i++) ChoiceChip(label: Icon(kIcons[i], size: 18), selected: ic == i, onSelected: (_) => set(() => ic = i))]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: Text(l.t('cancel'))),
          TextButton(onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final id = await app.saveSubject(Subject(id: s?.id, name: name.text.trim(), desc: desc.text.trim(), color: col, icon: ic, demo: s?.demo ?? false));
            if (dc.mounted) Navigator.pop(dc, id);
          }, child: Text(l.t('save'))),
        ],
      )));
}

// ------------------------------------------------------------------ add / edit session
class AddSession extends StatefulWidget {
  final Session? edit; final int? subjectId;
  const AddSession({super.key, this.edit, this.subjectId});
  @override State<AddSession> createState() => _AddState();
}
class _AddState extends State<AddSession> {
  int? sid; DateTime date = DateTime.now(); TimeOfDay st = const TimeOfDay(hour: 9, minute: 0), en = const TimeOfDay(hour: 10, minute: 0);
  final title = TextEditingController(), notes = TextEditingController(), dur = TextEditingController();
  String? err;
  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    sid = e?.subjectId ?? widget.subjectId ?? (app.subjects.isEmpty ? null : app.subjects.first.id);
    if (e != null) { date = e.start; st = TimeOfDay.fromDateTime(e.start); en = TimeOfDay.fromDateTime(e.end); title.text = e.title; notes.text = e.notes; }
  }
  Future<void> save() async {
    final l = app.l;
    final start = DateTime(date.year, date.month, date.day, st.hour, st.minute);
    DateTime end;
    if (dur.text.trim().isNotEmpty) {
      final m = int.tryParse(toLatin(dur.text.trim()));
      if (m == null || m <= 0) return setState(() => err = l.t('invalid'));
      end = start.add(Duration(minutes: m));
    } else {
      end = DateTime(date.year, date.month, date.day, en.hour, en.minute);
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1)); // crosses midnight
    }
    final mins = end.difference(start).inMinutes;
    if (sid == null || mins < 1 || mins > 1440) return setState(() => err = sid == null ? l.t('noSubjects') : l.t('invalid'));
    await app.saveSession(Session(id: widget.edit?.id, subjectId: sid, title: title.text.trim(), notes: notes.text.trim(), start: start, end: end, demo: widget.edit?.demo ?? false));
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext c) {
    final l = app.l;
    return Scaffold(
      appBar: AppBar(title: Text(widget.edit == null ? l.t('addSession') : l.t('editSession'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(value: sid, decoration: InputDecoration(labelText: l.t('subject'), border: const OutlineInputBorder()),
            items: [for (final s in app.subjects) DropdownMenuItem(value: s.id, child: Text(s.name))], onChanged: (v) => setState(() => sid = v))),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () async { final id = await subjectDialog(c); if (id != null) setState(() => sid = id); }),
        ]),
        const SizedBox(height: 12),
        TextField(controller: title, decoration: InputDecoration(labelText: l.t('title'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        ListTile(shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)), leading: const Icon(Icons.event), title: Text(l.t('date')), trailing: Text(l.date(date)),
          onTap: () async { final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1))); if (d != null) setState(() => date = d); }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () async { final t = await showTimePicker(context: c, initialTime: st); if (t != null) setState(() => st = t); }, child: Text('${l.t('from')}: ${l.tod(st.hour, st.minute)}'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () async { final t = await showTimePicker(context: c, initialTime: en); if (t != null) setState(() => en = t); }, child: Text('${l.t('to')}: ${l.tod(en.hour, en.minute)}'))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: dur, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.t('dur'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: notes, maxLines: 4, decoration: InputDecoration(labelText: l.t('notes'), border: const OutlineInputBorder())),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: TextStyle(color: Theme.of(c).colorScheme.error))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: Text(l.t('cancel')))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: save, child: Text(l.t('save')))),
        ]),
      ]),
    );
  }
}
