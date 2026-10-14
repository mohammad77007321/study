import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'i18n.dart';

final app = AppState();
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

class AppState extends ChangeNotifier {
  final db = Db();
  late SharedPreferences p;
  List<Subject> subjects = [];
  List<Session> sessions = [];
  String lang = 'fa';
  bool dark = false, jalali = true, faDigits = true;
  int dailyGoal = 120, weeklyGoal = 600;
  // timer state (in memory)
  DateTime? tStart, tResume; int tAccum = 0; bool tRunning = false; int? tSubject;

  L get l => L(lang, faDigits, jalali);
  Subject? sub(int? id) { for (final s in subjects) { if (s.id == id) return s; } return null; }

  Future<void> init() async {
    p = await SharedPreferences.getInstance();
    lang = p.getString('lang') ?? 'fa'; dark = p.getBool('dark') ?? false;
    jalali = p.getBool('jalali') ?? (lang == 'fa'); faDigits = p.getBool('digits') ?? true;
    dailyGoal = p.getInt('dg') ?? 120; weeklyGoal = p.getInt('wg') ?? 600;
    await db.open();
    if (!(p.getBool('seeded') ?? false)) { await db.seedDemo(); await p.setBool('seeded', true); }
    await reload();
  }
  Future<void> reload() async { subjects = await db.subjects(); sessions = await db.sessions(); notifyListeners(); }
  void pref(void Function() f) {
    f();
    p.setString('lang', lang); p.setBool('dark', dark); p.setBool('jalali', jalali); p.setBool('digits', faDigits);
    p.setInt('dg', dailyGoal); p.setInt('wg', weeklyGoal);
    notifyListeners();
  }
  Future<int> saveSubject(Subject s) async { final id = await db.saveSubject(s); await reload(); return id; }
  Future<void> delSubject(int id) async { await db.delSubject(id); await reload(); }
  Future<void> saveSession(Session s) async { await db.saveSession(s); await reload(); }
  Future<void> delSession(int id) async { await db.delSession(id); await reload(); }
  Future<void> clearDemo() async { await db.clearDemo(); await reload(); }

  // ---- timer ----
  int get elapsed => tAccum + (tRunning && tResume != null ? DateTime.now().difference(tResume!).inSeconds : 0);
  bool get timerActive => tStart != null;
  void timerStart() { tStart = DateTime.now(); tResume = tStart; tAccum = 0; tRunning = true; notifyListeners(); }
  void timerPause() { tAccum = elapsed; tRunning = false; notifyListeners(); }
  void timerResume() { tResume = DateTime.now(); tRunning = true; notifyListeners(); }
  Future<bool> timerFinish() async {
    final secs = elapsed, st = tStart!, sid = tSubject;
    tStart = null; tRunning = false; tAccum = 0; notifyListeners();
    if (secs < 60 || sid == null) return false;
    await saveSession(Session(subjectId: sid, title: sub(sid)?.name ?? '', start: st, end: st.add(Duration(seconds: secs))));
    return true;
  }

  // ---- statistics (sessions crossing midnight are split across days) ----
  Map<DateTime, int> perDay([Iterable<Session>? src]) {
    final m = <DateTime, int>{};
    for (final s in src ?? sessions) {
      var cur = s.start;
      while (cur.isBefore(s.end)) {
        final next = DateTime(cur.year, cur.month, cur.day + 1);
        final e = s.end.isBefore(next) ? s.end : next;
        m[dayOf(cur)] = (m[dayOf(cur)] ?? 0) + e.difference(cur).inMinutes;
        cur = e;
      }
    }
    return m;
  }
  int minutesOn(DateTime d) => perDay()[dayOf(d)] ?? 0;
  int weekMinutes(DateTime anyDayInWeek) {
    final ws = l.weekStart(anyDayInWeek), m = perDay();
    var t = 0; for (var i = 0; i < 7; i++) { t += m[DateTime(ws.year, ws.month, ws.day + i)] ?? 0; }
    return t;
  }
  int get streak {
    final m = perDay(); var d = dayOf(DateTime.now());
    if ((m[d] ?? 0) == 0) d = DateTime(d.year, d.month, d.day - 1);
    var c = 0; while ((m[d] ?? 0) > 0) { c++; d = DateTime(d.year, d.month, d.day - 1); }
    return c;
  }
  /// Bar buckets for a period: day (by hour), week, month (30 days), year (12 months).
  (List<String>, List<int>) buckets(String period) {
    final now = DateTime.now(), pd = perDay();
    if (period == 'day') {
      final v = List.filled(24, 0);
      for (final s in sessions) { if (dayOf(s.start) == dayOf(now)) v[s.start.hour] += s.minutes; }
      return (List.generate(24, (i) => i % 3 == 0 ? l.n(i) : ''), v);
    }
    if (period == 'year') {
      final v = List.filled(12, 0);
      final cy = jalali ? Jalali.now().year : now.year;
      pd.forEach((d, m) {
        if (jalali) { final j = Jalali.fromDateTime(d); if (j.year == cy) v[j.month - 1] += m; }
        else if (d.year == cy) { v[d.month - 1] += m; }
      });
      return (List.generate(12, (i) => l.n(i + 1)), v);
    }
    final n = period == 'week' ? 7 : 30;
    final first = period == 'week' ? l.weekStart(now) : DateTime(now.year, now.month, now.day - 29);
    final days = List.generate(n, (i) => DateTime(first.year, first.month, first.day + i));
    return (days.map((d) => period == 'week' ? l.wd(d).substring(0, l.fa ? 1 : 2) : (d.day % 5 == 0 ? l.n(d.day) : '')).toList(), days.map((d) => pd[d] ?? 0).toList());
  }
  String export() => jsonEncode({'subjects': subjects.map((s) => s.toMap()).toList(), 'sessions': sessions.map((s) => s.toMap()).toList()});
}
