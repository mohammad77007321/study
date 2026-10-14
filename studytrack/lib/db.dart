import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Subject {
  int? id; String name, desc; int color, icon; bool demo;
  Subject({this.id, required this.name, required this.color, this.icon = 0, this.desc = '', this.demo = false});
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'color': color, 'icon': icon, 'description': desc, 'demo': demo ? 1 : 0};
  factory Subject.fromMap(Map<String, Object?> m) => Subject(id: m['id'] as int, name: m['name'] as String, color: m['color'] as int, icon: m['icon'] as int, desc: (m['description'] as String?) ?? '', demo: m['demo'] == 1);
}

class Session {
  int? id, subjectId; String title, notes; DateTime start, end; bool demo;
  Session({this.id, required this.subjectId, required this.title, this.notes = '', required this.start, required this.end, this.demo = false});
  int get minutes => end.difference(start).inMinutes;
  Map<String, Object?> toMap() => {'id': id, 'subject_id': subjectId, 'title': title, 'notes': notes, 'start': start.millisecondsSinceEpoch, 'finish': end.millisecondsSinceEpoch, 'demo': demo ? 1 : 0};
  factory Session.fromMap(Map<String, Object?> m) => Session(id: m['id'] as int, subjectId: m['subject_id'] as int, title: (m['title'] as String?) ?? '', notes: (m['notes'] as String?) ?? '', start: DateTime.fromMillisecondsSinceEpoch(m['start'] as int), end: DateTime.fromMillisecondsSinceEpoch(m['finish'] as int), demo: m['demo'] == 1);
}

class Db {
  late Database d;
  Future<void> open() async {
    d = await openDatabase(join(await getDatabasesPath(), 'studytrack.db'), version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE subjects(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, color INTEGER, icon INTEGER, description TEXT, demo INTEGER DEFAULT 0)');
        await db.execute('CREATE TABLE sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE, title TEXT, notes TEXT, start INTEGER, finish INTEGER, demo INTEGER DEFAULT 0)');
      });
  }
  Future<List<Subject>> subjects() async => (await d.query('subjects', orderBy: 'id')).map(Subject.fromMap).toList();
  Future<List<Session>> sessions() async => (await d.query('sessions', orderBy: 'start DESC')).map(Session.fromMap).toList();
  Future<int> saveSubject(Subject s) async => s.id == null ? d.insert('subjects', s.toMap()..remove('id')) : (await d.update('subjects', s.toMap(), where: 'id=?', whereArgs: [s.id])) * 0 + s.id!;
  Future<void> delSubject(int id) => d.delete('subjects', where: 'id=?', whereArgs: [id]);
  Future<void> saveSession(Session s) async => s.id == null ? await d.insert('sessions', s.toMap()..remove('id')) : await d.update('sessions', s.toMap(), where: 'id=?', whereArgs: [s.id]);
  Future<void> delSession(int id) => d.delete('sessions', where: 'id=?', whereArgs: [id]);
  Future<void> clearDemo() async { await d.delete('sessions', where: 'demo=1'); await d.delete('subjects', where: 'demo=1'); }

  Future<void> seedDemo() async {
    final r = Random(7);
    final defs = [('ریاضی', 'Math', 0xFF4F46E5, 0), ('فیزیک', 'Physics', 0xFF14B8A6, 1), ('زبان انگلیسی', 'English', 0xFFF59E0B, 2), ('برنامه‌نویسی', 'Programming', 0xFFEC4899, 3)];
    final ids = <int>[];
    for (final x in defs) { ids.add(await saveSubject(Subject(name: '${x.$1} / ${x.$2}', color: x.$3, icon: x.$4, desc: 'Demo', demo: true))); }
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      if (r.nextInt(5) == 0) continue;
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      for (var k = 0; k < 1 + r.nextInt(2); k++) {
        final st = day.add(Duration(hours: 8 + r.nextInt(12), minutes: r.nextInt(4) * 15));
        final en = st.add(Duration(minutes: 25 + r.nextInt(100)));
        if (en.isAfter(now)) continue;
        await saveSession(Session(subjectId: ids[r.nextInt(4)], title: 'Demo', start: st, end: en, demo: true));
      }
    }
  }
}
