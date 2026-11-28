import 'package:intl/intl.dart';

/// Formats d'affichage. Les dates du backend sont en heure locale de Bamako
/// (UTC), sans fuseau (docs/API.md §2.1) : elles sont affichées telles quelles.
class Format {
  Format._();

  static final _milliers = NumberFormat('#,###', 'fr_FR');

  /// 1250.0 → « 1 250 FCFA »
  static String fcfa(num montant) =>
      '${_milliers.format(montant.round()).replaceAll(RegExp(r'[,  ]'), ' ')} FCFA';

  /// « 2030-01-15T10:20:00 » → « 15/01/2030 10:20 »
  static String dateHeure(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  /// « 2030-01-15T10:20:00 » → « 10:20 »
  static String heureDe(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('HH:mm').format(d);
  }

  /// « 10:00:00 » → « 10:00 »
  static String heure(String? hms) {
    if (hms == null || hms.isEmpty) return '-';
    return hms.length >= 5 ? hms.substring(0, 5) : hms;
  }

  /// « 2030-01-15 » → « 15/01/2030 »
  static String date(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '-';
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : DateFormat('dd/MM/yyyy').format(d);
  }

  /// « samedi 28 novembre » (nécessite `initializeDateFormatting('fr_FR')`).
  static String jourLong([DateTime? d]) =>
      DateFormat('EEEE d MMMM', 'fr_FR').format(d ?? DateTime.now());

  /// Date du jour au format API (`yyyy-MM-dd`).
  static String aujourdhui() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}

int? parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

num parseNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v?.toString() ?? '') ?? 0;
}

String? parseString(dynamic v) => v?.toString();
