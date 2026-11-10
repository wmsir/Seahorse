import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '¥',
    decimalDigits: 2,
  );

  static String currency(num? amount) {
    if (amount == null) return '¥0.00';
    return _currencyFormat.format(amount);
  }

  static String date(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  static String time(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }

  static String maskPhone(String? phone) {
    if (phone == null || phone.length < 11) return phone ?? '';
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
}
