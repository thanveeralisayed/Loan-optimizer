import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/utils/indian_currency_formatter.dart';

void main() {
  group('IndianCurrencyFormatter Tests', () {
    test('Formats full Indian currency with Rupee symbol', () {
      expect(IndianCurrencyFormatter.format(5000000), '₹50,00,000');
      expect(IndianCurrencyFormatter.format(4265400), '₹42,65,400');
      expect(IndianCurrencyFormatter.format(43391), '₹43,391');
      expect(IndianCurrencyFormatter.format(10400000), '₹1,04,00,000');
      expect(IndianCurrencyFormatter.format(0), '₹0');
    });

    test('Formats full Indian currency with decimals', () {
      expect(IndianCurrencyFormatter.format(43391.14, includeDecimals: true),
          '₹43,391.14');
    });

    test('Formats without symbol', () {
      expect(IndianCurrencyFormatter.formatWithoutSymbol(5000000), '50,00,000');
      expect(IndianCurrencyFormatter.formatWithoutSymbol(125000), '1,25,000');
    });

    test('Formats compact Indian currency', () {
      expect(IndianCurrencyFormatter.formatCompact(5000000), '₹50.00L');
      expect(IndianCurrencyFormatter.formatCompact(10400000), '₹1.04Cr');
      expect(IndianCurrencyFormatter.formatCompact(1486500), '₹14.87L');
      expect(IndianCurrencyFormatter.formatCompact(43391), '₹43.4K');
      expect(IndianCurrencyFormatter.formatCompact(500), '₹500');
      expect(IndianCurrencyFormatter.formatCompact(-500000), '-₹5.00L');
    });

    test('Parses formatted string to numeric double', () {
      expect(IndianCurrencyFormatter.parse('₹50,00,000'), 5000000.0);
      expect(IndianCurrencyFormatter.parse('42,65,400'), 4265400.0);
      expect(IndianCurrencyFormatter.parse('  ₹ 1,00,000 '), 100000.0);
      expect(IndianCurrencyFormatter.parse(''), 0.0);
      expect(IndianCurrencyFormatter.parse('invalid'), 0.0);
    });

    test('Converts amounts to Indian English words', () {
      expect(IndianCurrencyFormatter.toWords(5000000), 'Fifty Lakhs Rupees');
      expect(IndianCurrencyFormatter.toWords(10000000), 'One Crore Rupees');
      expect(IndianCurrencyFormatter.toWords(20000000), 'Two Crores Rupees');
      expect(IndianCurrencyFormatter.toWords(100000), 'One Lakh Rupees');
      expect(IndianCurrencyFormatter.toWords(2500000),
          'Twenty Five Lakhs Rupees');
      expect(IndianCurrencyFormatter.toWords(0), 'Zero Rupees');
      expect(IndianCurrencyFormatter.toWords(43391),
          'Forty Three Thousand Three Hundred Ninety One Rupees');
      expect(IndianCurrencyFormatter.toWords(-500000),
          'Minus Five Lakhs Rupees');
    });
  });
}
