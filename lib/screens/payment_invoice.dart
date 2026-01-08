import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Assuming Timestamp is used

class PaymentInvoicePage extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final double? balance; // Current balance AFTER this transaction

  const PaymentInvoicePage({
    super.key,
    required this.transaction,
    this.balance,
  });

  // Determine if transaction increases balance (credit: money received)
  // bool get _isCredit {
  //   final type = (transaction['type'] ?? '').toString().toLowerCase();
  //   return type.contains('received') ||
  //       type.contains('credit') ||
  //       type.contains('deposit') ||
  //       type.contains('income') ||
  //       type.contains('payment in');
  // }

  double get _amount => (transaction['amount'] as num).toDouble();
  double get _balanceNew => (transaction['newBalance'] ?? 0.0).toDouble();

  // double get _oldBalance {
  //   return _isCredit ? balance - _amount : balance + _amount;
  // }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final pdf = pw.Document();
      final date = (transaction['timestamp'] as Timestamp).toDate();
      final entityName = transaction['entityName'] ?? 'Unknown';
      final entityType =
          transaction['entityType']?.toString().toLowerCase() == 'customer'
          ? 'Customer'
          : 'Vendor';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.teal, width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Divider(thickness: 2, color: PdfColors.grey300),
                  pw.SizedBox(height: 30),

                  _pdfRow('Name:', entityName),
                  pw.SizedBox(height: 15),
                  _pdfRow('Type:', entityType),
                  pw.SizedBox(height: 15),
                  _pdfRow('Transaction:', transaction['type'] ?? 'Unknown'),
                  pw.SizedBox(height: 15),
                  _pdfRow(
                    'Date:',
                    DateFormat('dd MMM yyyy, hh:mm a').format(date),
                  ),

                  pw.SizedBox(height: 30),
                  pw.Divider(thickness: 2, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Transaction Amount:',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'SAR ${_amount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 20),
                        pw.Divider(color: PdfColors.grey400),
                        pw.SizedBox(height: 15),
                        // pw.Row(
                        //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        //   children: [
                        // pw.Text(
                        //   'Previous Balance:',
                        //   style: const pw.TextStyle(
                        //     fontSize: 14,
                        //     color: PdfColors.grey700,
                        //   ),
                        // ),
                        // pw.Text(
                        //   'SAR ${_oldBalance.toStringAsFixed(2)}',
                        //   style: const pw.TextStyle(
                        //     fontSize: 14,
                        //     color: PdfColors.grey700,
                        //   ),
                        // ),
                        //   ],
                        // ),
                        // pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Balance:',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'SAR ${_balanceNew.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                                // _newBalance >= 0
                                //     ? PdfColors.black
                                //     : PdfColors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName =
          'Payment_Receipt_${entityName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(date)}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Payment Receipt - $entityName',
        text:
            'Payment receipt for $entityName - SAR ${_amount.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 16),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _printReceipt() async {
    final date = (transaction['timestamp'] as Timestamp).toDate();
    final entityName = transaction['entityName'] ?? 'Unknown';
    final entityType =
        transaction['entityType']?.toString().toLowerCase() == 'customer'
        ? 'Customer'
        : 'Vendor';

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Same layout as _generateAndSharePDF (reused logic for consistency)
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.teal, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(thickness: 2, color: PdfColors.grey300),
              pw.SizedBox(height: 30),
              _pdfRow('Name:', entityName),
              pw.SizedBox(height: 15),
              _pdfRow('Type:', entityType),
              pw.SizedBox(height: 15),
              _pdfRow('Transaction:', transaction['type'] ?? 'Unknown'),
              pw.SizedBox(height: 15),
              _pdfRow('Date:', DateFormat('dd MMM yyyy, hh:mm a').format(date)),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Transaction Amount:',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'SAR ${_amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 15),
                    // pw.Row(
                    //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     pw.Text(
                    //       'Previous Balance:',
                    //       style: const pw.TextStyle(
                    //         fontSize: 14,
                    //         color: PdfColors.grey700,
                    //       ),
                    //     ),
                    //     pw.Text(
                    //       'SAR ${_oldBalance.toStringAsFixed(2)}',
                    //       style: const pw.TextStyle(
                    //         fontSize: 14,
                    //         color: PdfColors.grey700,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Balance:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'SAR ${_balanceNew.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                            //  _newBalance >= 0
                            //     ? PdfColors.black
                            //     : PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final date = (transaction['timestamp'] as Timestamp).toDate();
    final entityType =
        transaction['entityType']?.toString().toLowerCase() == 'customer'
        ? 'Customer'
        : 'Vendor';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Receipt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (balance != null) {
              Navigator.pop(context);

              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.print, color: Colors.white),
        //     onPressed: _printReceipt,
        //     tooltip: 'Print Receipt',
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.share, color: Colors.white),
        //     onPressed: () => _generateAndSharePDF(context),
        //     tooltip: 'Share PDF',
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'PAYMENT RECEIPT',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _row('Name', transaction['entityName'] ?? 'Unknown'),
                      _row('Type', entityType),
                      _row('Transaction', transaction['type'] ?? 'Unknown'),
                      _row(
                        'Date',
                        DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      ),
                      const Divider(height: 32),
                      _row(
                        'Transaction Amount',
                        'SAR ${_amount.toStringAsFixed(2)}',
                        bold: true,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // _row(
                            //   'Previous Balance',
                            //   'SAR ${_oldBalance.toStringAsFixed(2)}',
                            // ),
                            // const SizedBox(height: 8),
                            _row(
                              'Balance',
                              'SAR ${_balanceNew.toStringAsFixed(2)}',
                              bold: true,
                              color: Colors.grey[800],
                              //  _newBalance >= 0
                              //     ? Colors.green
                              //     : Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Center(
                        child: Text(
                          'Thank you!',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: _printReceipt,
                //     icon: const Icon(Icons.print),
                //     label: const Text('Print', style: TextStyle(fontSize: 16)),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.grey[700],
                //       foregroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _generateAndSharePDF(context).then((_) {
                        if (balance != null) {
                          Navigator.pop(context);

                          Navigator.pop(context);
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                        }
                        // Optionally show a snackbar or confirmation
                      });
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      'Share PDF',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
