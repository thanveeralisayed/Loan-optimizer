import 'package:intl/intl.dart';

class IndianCurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _rawIndianFormat = NumberFormat.decimalPattern('en_IN');

  /// Formats amount into standard Indian currency representation:
  /// e.g. 5000000 -> "₹50,00,000"
  static String format(num amount, {bool includeDecimals = false}) {
    if (includeDecimals) {
      return _decimalCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount.round());
  }

  /// Formats amount without Rupee symbol:
  /// e.g. 5000000 -> "50,00,000"
  static String formatWithoutSymbol(num amount) {
    return _rawIndianFormat.format(amount.round());
  }

  /// Formats compact Indian currency:
  /// e.g. 5000000 -> "₹50.00L"
  /// e.g. 10400000 -> "₹1.04Cr"
  /// e.g. 43391 -> "₹43.4K"
  static String formatCompact(num amount, {bool includeSymbol = true}) {
    final prefix = includeSymbol ? '₹' : '';
    final sign = amount < 0 ? '-' : '';
    final absAmount = amount.abs().toDouble();

    if (absAmount >= 10000000) {
      // Crores
      final val = absAmount / 10000000;
      return '$sign$prefix${val.toStringAsFixed(2)}Cr';
    } else if (absAmount >= 100000) {
      // Lakhs
      final val = absAmount / 100000;
      return '$sign$prefix${val.toStringAsFixed(2)}L';
    } else if (absAmount >= 1000) {
      // Thousands
      final val = absAmount / 1000;
      return '$sign$prefix${val.toStringAsFixed(1)}K';
    } else {
      return '$sign$prefix${absAmount.toStringAsFixed(0)}';
    }
  }

  /// Parses an Indian formatted string back to double:
  /// e.g. "₹50,00,000" -> 5000000.0
  static double parse(String value) {
    final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Converts a numeric amount to Indian English words:
  /// e.g. 5000000 -> "Fifty Lakhs Rupees"
  /// e.g. 4265400 -> "Forty Two Lakhs Sixty Five Thousand Four Hundred Rupees"
  static String toWords(num amount) {
    if (amount == 0) return 'Zero Rupees';
    final isNegative = amount < 0;
    int n = amount.abs().round();

    final parts = <String>[];

    final crores = n ~/ 10000000;
    n %= 10000000;

    final lakhs = n ~/ 100000;
    n %= 100000;

    final thousands = n ~/ 1000;
    n %= 1000;

    final hundreds = n ~/ 100;
    n %= 100;

    final remainder = n;

    if (crores > 0) {
      parts.add('${_twoDigitWords(crores)} Crore${crores > 1 ? 's' : ''}');
    }
    if (lakhs > 0) {
      parts.add('${_twoDigitWords(lakhs)} Lakh${lakhs > 1 ? 's' : ''}');
    }
    if (thousands > 0) {
      parts.add('${_twoDigitWords(thousands)} Thousand');
    }
    if (hundreds > 0) {
      parts.add('${_twoDigitWords(hundreds)} Hundred');
    }
    if (remainder > 0) {
      parts.add(_twoDigitWords(remainder));
    }

    final prefix = isNegative ? 'Minus ' : '';
    return '$prefix${parts.join(' ')} Rupees';
  }

  static String _twoDigitWords(int n) {
    const units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];

    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    if (n < 20) {
      return units[n];
    } else {
      final t = n ~/ 10;
      final u = n % 10;
      if (u == 0) {
        return tens[t];
      }
      return '${tens[t]} ${units[u]}';
    }
  }
}
