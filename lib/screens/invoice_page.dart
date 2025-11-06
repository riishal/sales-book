import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final balance = data['currentBill'] - data['paidNow'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _generatePDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareInvoice(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blue],
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
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
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
                          color: Colors.white,
                        ),
                      ),
                      const Divider(height: 32, color: Colors.white),
                      Text(
                        'Name: ${data['name']}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone: ${data['phone']}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const Divider(height: 32, color: Colors.white),
                      const Text(
                        'Products:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...((data['products'] as List).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p['name']} x ${p['qty']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                '﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const Divider(height: 32, color: Colors.white),
                      _buildRow('Previous Balance', data['previousBalance']),
                      _buildRow('Additional Charge', data['additionalCharge']),
                      _buildRow('Discount', data['discount']),
                      _buildRow('Tax', data['tax']),
                      const Divider(height: 24, color: Colors.white),
                      _buildRow('Total Bill', data['currentBill'], isTotal: true),
                      _buildRow('Paid Now', data['paidNow']),
                      const Divider(height: 24, color: Colors.white),
                      _buildRow('Balance', balance, isBalance: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareViaWhatsApp(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Share via WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
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
    dynamic value, {
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
              color: Colors.white,
            ),
          ),
          Text(
            '﷼${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal || isBalance ? 18 : 16,
              fontWeight: isTotal || isBalance
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Name: ${data['name']}'),
            pw.Text('Phone: ${data['phone']}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text(
              'Products:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...((data['products'] as List).map(
              (p) => pw.Text(
                '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}',
              ),
            )),
            pw.SizedBox(height: 20),
            pw.Text('Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}'),
            pw.Text('Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}'),
            pw.Text(
              'Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _shareInvoice(BuildContext context) async {
    final text =
        '''
Invoice
Name: ${data['name']}
Phone: ${data['phone']}
Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
Products:
${(data['products'] as List).map((p) => '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}').join('\n')}
Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}
Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}
Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}
''';
    await Share.share(text);
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final text =
        '''
Invoice
Name: ${data['name']}
Phone: ${data['phone']}
Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
Products:
${(data['products'] as List).map((p) => '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}').join('\n')}
Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}
Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}
Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}
''';
    final phone = data['phone'].replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
