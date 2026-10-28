import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/utils/indian_currency_formatter.dart';
import '../models/amortization_schedule.dart';
import '../models/loan_config.dart';

class ExportService {
  /// Generates a valid CSV string representing the entire amortization schedule
  static String generateCsv(LoanAmortizationResult result) {
    final List<List<dynamic>> rows = [
      [
        'Month',
        'Year',
        'Date',
        'Opening Balance (INR)',
        'EMI (INR)',
        'Principal Paid (INR)',
        'Interest Paid (INR)',
        'Extra Prepayment (INR)',
        'Closing Balance (INR)',
      ]
    ];

    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final row in result.optimizedSchedule) {
      rows.add([
        row.monthIndex,
        row.yearIndex,
        dateFormat.format(row.date),
        row.openingBalance.round(),
        row.emi.round(),
        row.principalPaid.round(),
        row.interestPaid.round(),
        row.extraPrepayment.round(),
        row.closingBalance.round(),
      ]);
    }

    return csv.encode(rows);
  }

  /// Generates a PDF document for loan amortization breakdown
  static Future<List<int>> generatePdf({
    required LoanConfig config,
    required LoanAmortizationResult result,
  }) async {
    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = const pw.TextStyle(fontSize: 8);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('LoanOpt Amortization Statement', style: titleStyle),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${config.name} (No. ${config.loanNumber})',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    '100% Offline & Verified',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, height: 20),
          // Loan Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Sanctioned Principal:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      IndianCurrencyFormatter.format(config.principal).replaceAll('₹', 'Rs. '),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Interest Rate:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      '${config.annualInterestRate}% (${config.rateType.displayName})',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Interest Saved:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      IndianCurrencyFormatter.format(result.totalInterestSaved).replaceAll('₹', 'Rs. '),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Tenure Reduced:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      '-${result.monthsSaved} Months',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Yearly Amortization Schedule',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Year',
              'Opening Balance',
              'Total EMI Paid',
              'Principal Paid',
              'Interest Paid',
              'Extra Prepayment',
              'Closing Balance',
            ],
            headerStyle: headerStyle,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: cellStyle,
            cellAlignment: pw.Alignment.centerRight,
            data: result.yearlySummaries.map((y) {
              return [
                'Year ${y.yearIndex} (${y.yearNumber})',
                IndianCurrencyFormatter.format(y.openingBalance).replaceAll('₹', 'Rs. '),
                IndianCurrencyFormatter.format(y.totalEmiPaid).replaceAll('₹', 'Rs. '),
                IndianCurrencyFormatter.format(y.totalPrincipalPaid).replaceAll('₹', 'Rs. '),
                IndianCurrencyFormatter.format(y.totalInterestPaid).replaceAll('₹', 'Rs. '),
                IndianCurrencyFormatter.format(y.totalPrepaymentPaid).replaceAll('₹', 'Rs. '),
                IndianCurrencyFormatter.format(y.closingBalance).replaceAll('₹', 'Rs. '),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
