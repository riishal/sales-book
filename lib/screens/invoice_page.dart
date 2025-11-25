import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String type;

  const InvoicePage({
    super.key,
    required this.docId,
    required this.data,
    required this.type,
  });

  String _generateInvoiceText() {
    double subtotal = 0;
    final productsList = (data['products'] as List? ?? [])
        .map((p) {
          final total = (p['rate'] ?? 0.0) * (p['qty'] as num? ?? 0);
          subtotal += total;
          return '${p['name']} x ${p['qty']} - riyal ${total.toStringAsFixed(2)}';
        })
        .join('\n');

    final balance =
        (data['currentBill'] ?? data['amount'] ?? 0.0) -
        (data['paidNow'] ?? 0.0);

    return '''
      *INVOICE*
      -----------------
      Name: ${data['name'] ?? data['entityName']}
      Phone: ${data['phone'] ?? 'N/A'}
      Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
      -----------------
      *Products:*
      $productsList
      -----------------
      Subtotal: riyal ${subtotal.toStringAsFixed(2)}
      Additional Charge: riyal ${(data['additionalCharge'] ?? 0.0).toStringAsFixed(2)}
      Discount: -riyal ${(data['discount'] ?? 0.0).toStringAsFixed(2)}
      Tax: ${(data['tax'] ?? 0.0)}%
      Previous Balance: riyal ${(data['previousBalance'] ?? 0.0).toStringAsFixed(2)}
      -----------------
      *Total Bill: riyal ${(data['currentBill'] ?? data['amount'] ?? 0.0).toStringAsFixed(2)}*
      Paid Now: riyal ${(data['paidNow'] ?? 0.0).toStringAsFixed(2)}
      *Balance: riyal ${balance.toStringAsFixed(2)}*
    ''';
  }

  Future<Uint8List> _generatePDFBytes() async {
    final pdf = pw.Document();
    double subtotal = 0;
    final productsList = (data['products'] as List? ?? []).map((p) {
      final total = (p['rate'] ?? 0.0) * (p['qty'] as num? ?? 0);
      subtotal += total;
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('${p['name']} x ${p['qty']}'),
          pw.Text('riyal ${total.toStringAsFixed(2)}'),
        ],
      );
    }).toList();

    final balance =
        (data['currentBill'] ?? data['amount'] ?? 0.0) -
        (data['paidNow'] ?? 0.0);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.Text('Name: ${data['name'] ?? data['entityName']}'),
            pw.Text('Phone: ${data['phone'] ?? 'N/A'}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
            pw.Divider(),
            pw.Text(
              'Products:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...productsList,
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal'),
                pw.Text('riyal ${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Additional Charge'),
                pw.Text(
                  'riyal ${(data['additionalCharge'] ?? 0.0).toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Discount'),
                pw.Text(
                  '-riyal ${(data['discount'] ?? 0.0).toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Tax'), pw.Text('${(data['tax'] ?? 0.0)}%')],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Previous Balance'),
                pw.Text(
                  'riyal ${(data['previousBalance'] ?? 0.0).toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Bill',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'riyal ${(data['currentBill'] ?? data['amount'] ?? 0.0).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid Now'),
                pw.Text('riyal ${(data['paidNow'] ?? 0.0).toStringAsFixed(2)}'),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Balance',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'riyal ${balance.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        (data['currentBill'] ?? data['amount'] ?? 0.0) -
        (data['paidNow'] ?? 0.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invoice',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
            onPressed: () async {
              final pdfBytes = await _generatePDFBytes();
              await Printing.layoutPdf(onLayout: (format) => pdfBytes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () async {
              final pdfBytes = await _generatePDFBytes();
              final xFile = XFile.fromData(
                pdfBytes,
                name: 'invoice_${docId}.pdf',
                mimeType: 'application/pdf',
              );
              await Share.shareXFiles([xFile], text: _generateInvoiceText());
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.black87.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.black87.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 32, color: Colors.black87),
                      Text(
                        'Name: ${data['name'] ?? data['entityName']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone: ${data['phone'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 32, color: Colors.black87),
                      const Text(
                        'Products:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...((data['products'] as List? ?? []).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p['name']} x ${p['qty']}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                '﷼${((p['rate'] ?? 0.0) * (p['qty'] as num? ?? 0)).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const Divider(height: 32, color: Colors.black87),
                      _buildRow(
                        'Previous Balance',
                        data['previousBalance'] ?? 0.0,
                      ),
                      _buildRow(
                        'Additional Charge',
                        data['additionalCharge'] ?? 0.0,
                      ),
                      _buildRow('Discount', data['discount'] ?? 0.0),
                      _buildRow('Tax', data['tax'] ?? 0.0),
                      const Divider(height: 24, color: Colors.black87),
                      _buildRow(
                        'Total Bill',
                        data['currentBill'] ?? data['amount'] ?? 0.0,
                        isTotal: true,
                      ),
                      _buildRow('Paid Now', data['paidNow'] ?? 0.0),
                      const Divider(height: 24, color: Colors.black87),
                      _buildRow('Balance', balance, isBalance: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfBytes = await _generatePDFBytes();
                    final xFile = XFile.fromData(
                      pdfBytes,
                      name: 'invoice_${docId}.pdf',
                      mimeType: 'application/pdf',
                    );
                    await Share.shareXFiles([
                      xFile,
                    ], text: _generateInvoiceText());
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Invoice PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    num value, {
    bool isTotal = false,
    bool isBalance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal || isBalance ? 18 : 16,
              fontWeight: isTotal || isBalance
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            '﷼${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal || isBalance ? 18 : 16,
              fontWeight: isTotal || isBalance
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
