import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

const _fa = {
  'home': 'خانه', 'history': 'تاریخچه', 'analytics': 'آمار', 'settings': 'تنظیمات', 'hello': 'سلام 👋', 'today': 'امروز',
  'goal': 'هدف', 'start': 'شروع', 'pause': 'توقف', 'resume': 'ادامه', 'finish': 'پایان', 'subject': 'درس', 'subjects': 'درس‌ها',
  'addSession': 'ثبت جلسه مطالعه', 'editSession': 'ویرایش جلسه', 'date': 'تاریخ', 'from': 'شروع', 'to': 'پایان', 'dur': 'یا مدت (دقیقه)',
  'title': 'عنوان جلسه', 'notes': 'یادداشت: چه خواندم، چه چیزی مانده؟', 'save': 'ذخیره', 'cancel': 'انصراف', 'delete': 'حذف',
  'confirmDel': 'مطمئن هستید که حذف شود؟', 'noData': 'هنوز داده‌ای نیست. اولین جلسه را ثبت کنید.', 'search': 'جستجو...', 'all': 'همه',
  'total': 'مجموع مطالعه', 'sessions': 'جلسات', 'avg': 'میانگین روزانه', 'longest': 'طولانی‌ترین جلسه', 'streak': 'روزهای متوالی',
  'thisWeek': 'این هفته', 'lastWeek': 'هفته قبل', 'bestDay': 'بهترین روز', 'share': 'سهم هر درس', 'day': 'روز', 'week': 'هفته',
  'month': 'ماه', 'year': 'سال', 'language': 'زبان', 'dark': 'حالت تاریک', 'dailyGoal': 'هدف روزانه (دقیقه)', 'weeklyGoal': 'هدف هفتگی (دقیقه)',
  'jalali': 'تقویم شمسی', 'digits': 'ارقام فارسی', 'export': 'خروجی پشتیبان (کپی JSON)', 'copied': 'در کلیپ‌بورد کپی شد',
  'demoRemove': 'حذف داده‌های نمونه', 'name': 'نام', 'desc': 'توضیحات', 'newSubject': 'درس جدید', 'invalid': 'ورودی نامعتبر است', 'recent': 'اخیراً خوانده‌شده',
  'noSubjects': 'ابتدا یک درس بسازید', 'h': 'س', 'm': 'د', 'min30': '+۳۰ دقیقه', 'min60': '+۶۰ دقیقه', 'vs': 'مقایسه هفته‌ها', 'goalRate': 'تحقق هدف',
  'weekly': 'هفتگی', 'daily': 'روزانه', 'manage': 'مدیریت درس‌ها', 'edit': 'ویرایش', 'hoursTip': 'ساعت',
};
const _en = {
  'home': 'Home', 'history': 'History', 'analytics': 'Analytics', 'settings': 'Settings', 'hello': 'Hello 👋', 'today': 'Today',
  'goal': 'Goal', 'start': 'Start', 'pause': 'Pause', 'resume': 'Resume', 'finish': 'Finish', 'subject': 'Subject', 'subjects': 'Subjects',
  'addSession': 'Add study session', 'editSession': 'Edit session', 'date': 'Date', 'from': 'Start', 'to': 'End', 'dur': 'or duration (min)',
  'title': 'Session title', 'notes': 'Notes: what I studied, what remains', 'save': 'Save', 'cancel': 'Cancel', 'delete': 'Delete',
  'confirmDel': 'Are you sure you want to delete this?', 'noData': 'No data yet. Add your first session.', 'search': 'Search...', 'all': 'All',
  'total': 'Total study', 'sessions': 'Sessions', 'avg': 'Daily average', 'longest': 'Longest session', 'streak': 'Day streak',
  'thisWeek': 'This week', 'lastWeek': 'Last week', 'bestDay': 'Best day', 'share': 'Time by subject', 'day': 'Day', 'week': 'Week',
  'month': 'Month', 'year': 'Year', 'language': 'Language', 'dark': 'Dark mode', 'dailyGoal': 'Daily goal (min)', 'weeklyGoal': 'Weekly goal (min)',
  'jalali': 'Jalali calendar', 'digits': 'Persian digits', 'export': 'Backup (copy JSON)', 'copied': 'Copied to clipboard',
  'demoRemove': 'Remove demo data', 'name': 'Name', 'desc': 'Description', 'newSubject': 'New subject', 'invalid': 'Invalid input', 'recent': 'Recently studied',
  'noSubjects': 'Create a subject first', 'h': 'h', 'm': 'm', 'min30': '30+ min', 'min60': '60+ min', 'vs': 'Week comparison', 'goalRate': 'Goal completion',
  'weekly': 'Weekly', 'daily': 'Daily', 'manage': 'Manage subjects', 'edit': 'Edit', 'hoursTip': 'h',
};
const _faMonths = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
const _faWd = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'];
const _enWd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String toLatin(String s) {
  const f = '۰۱۲۳۴۵۶۷۸۹', a = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((c) => f.contains(c) ? '${f.indexOf(c)}' : a.contains(c) ? '${a.indexOf(c)}' : c).join();
}

class L {
  final String lang; final bool faDigits, jalali;
  L(this.lang, this.faDigits, this.jalali);
  bool get fa => lang == 'fa';
  String t(String k) => (fa ? _fa[k] : _en[k]) ?? k;
  String n(Object x) {
    var s = '$x';
    if (fa && faDigits) { const f = '۰۱۲۳۴۵۶۷۸۹'; s = s.replaceAllMapped(RegExp(r'\d'), (m) => f[int.parse(m[0]!)]); }
    return s;
  }
  String dur(int min) => min < 60 ? '${n(min)}${t('m')}' : '${n(min ~/ 60)}${t('h')} ${n(min % 60)}${t('m')}';
  String hm(DateTime d) => n('${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}');
  String tod(int h, int m) => n('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
  String date(DateTime d) {
    if (jalali) { final j = Jalali.fromDateTime(d); return n('${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}'); }
    return n(DateFormat('yyyy-MM-dd').format(d));
  }
  String longDate(DateTime d) {
    if (jalali) { final j = Jalali.fromDateTime(d); return '${_faWd[d.weekday - 1]} ${n(j.day)} ${_faMonths[j.month - 1]} ${n(j.year)}'; }
    return n(DateFormat('EEEE, d MMMM y', 'en').format(d));
  }
  String wd(DateTime d) => fa ? _faWd[d.weekday - 1] : _enWd[d.weekday - 1];
  DateTime weekStart(DateTime d) {
    final off = jalali ? (d.weekday + 1) % 7 : d.weekday - 1;
    return DateTime(d.year, d.month, d.day - off);
  }
}
