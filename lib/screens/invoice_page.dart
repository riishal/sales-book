import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

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

  Future<Uint8List> _generateModernInvoicePdf() async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    // Parse products
    final List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(
      data['products'] ?? [],
    );

    double subtotal = 0.0;
    for (var p in products) {
      final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
      subtotal += rate * qty;
    }

    final additionalCharge =
        (data['additionalCharge'] as num?)?.toDouble() ?? 0.0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0.0;
    final taxPercent = (data['tax'] as num?)?.toDouble() ?? 0.0;
    final previousBalance =
        (data['previousBalance'] as num?)?.toDouble() ?? 0.0;

    final taxAmount = subtotal * (taxPercent / 100);
    final totalBeforeBalance =
        subtotal + additionalCharge - discount + taxAmount;
    final grandTotal = totalBeforeBalance + previousBalance;
    final paidNow = (data['paidNow'] as num?)?.toDouble() ?? 0.0;
    final balanceDue = grandTotal - paidNow;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "INVOICE",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 30,
                        color: PdfColors.teal700,
                      ),
                    ),
                    // pw.SizedBox(height: 8),
                    // pw.Text(
                    //   "Invoice #$docId",
                    //   style: pw.TextStyle(font: boldFont, fontSize: 14),
                    // ),
                    pw.Text(
                      "Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
                // pw.Container(
                //   padding: const pw.EdgeInsets.all(12),
                //   decoration: pw.BoxDecoration(
                //     color: PdfColors.teal50,
                //     borderRadius: pw.BorderRadius.circular(8),
                //   ),
                //   child: pw.Text(
                //     "Your Business Name\nRiyadh, Saudi Arabia",
                //     style: pw.TextStyle(
                //       font: boldFont,
                //       fontSize: 12,
                //       color: PdfColors.teal900,
                //     ),
                //     textAlign: pw.TextAlign.right,
                //   ),
                // ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Bill To
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Bill To",
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    data['name'] ?? data['entityName'] ?? 'Customer',
                    style: pw.TextStyle(font: boldFont, fontSize: 18),
                  ),
                  pw.Text(
                    "Phone: ${data['phone'] ?? 'N/A'}",
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Products Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
              defaultColumnWidth: const pw.FlexColumnWidth(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  children: [
                    _tableHeader("Item"),
                    _tableHeader("Qty", align: pw.TextAlign.center),
                    _tableHeader("Rate", align: pw.TextAlign.right),
                    _tableHeader("Amount", align: pw.TextAlign.right),
                  ],
                ),
                ...products.map((p) {
                  final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
                  final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
                  final amount = rate * qty;
                  return pw.TableRow(
                    children: [
                      _tableCell(p['name']?.toString() ?? '', padding: 12),
                      _tableCell(
                        qty.toInt().toString(),
                        align: pw.TextAlign.center,
                      ),
                      _tableCell(
                        rate.toStringAsFixed(2),
                        align: pw.TextAlign.right,
                      ),
                      _tableCell(
                        amount.toStringAsFixed(2),
                        align: pw.TextAlign.right,
                        isBold: true,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.Spacer(),

            // Summary Box (Right Side)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 280,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow("Subtotal", subtotal, font, boldFont),
                        _summaryRow(
                          "Additional Charge",
                          additionalCharge,
                          font,
                          boldFont,
                        ),
                        _summaryRow("Discount", -discount, font, boldFont),
                        _summaryRow(
                          "Tax ($taxPercent%)",
                          taxAmount,
                          font,
                          boldFont,
                        ),
                        _summaryRow(
                          "Previous Balance",
                          previousBalance,
                          font,
                          boldFont,
                        ),
                        pw.Divider(thickness: 1, color: PdfColors.grey600),
                        _summaryRow(
                          "Total Amount Due",
                          grandTotal,
                          font,
                          boldFont,
                          isBold: true,
                          size: 16,
                        ),
                        _summaryRow("Paid Now", paidNow, font, boldFont),
                        pw.Divider(thickness: 2),
                        _summaryRow(
                          "Balance Due",
                          balanceDue,
                          font,
                          boldFont,
                          isBold: true,
                          size: 18,
                          color: balanceDue > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Footer
            pw.Center(
              child: pw.Text(
                "Thank you for your business!",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            // pw.Center(
            //   child: pw.Text(
            //     "For any queries, contact us at support@yourbusiness.com",
            //     style: pw.TextStyle(
            //       font: font,
            //       fontSize: 10,
            //       color: PdfColors.grey600,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Helper: Table Header
  pw.Widget _tableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: align,
      ),
    );
  }

  // Helper: Table Cell
  pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    double padding = 10,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 11,
        ),
      ),
    );
  }

  // Helper: Summary Row
  pw.Widget _summaryRow(
    String label,
    double amount,
    pw.Font font,
    pw.Font boldFont, {
    bool isBold = false,
    double size = 13,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: isBold ? boldFont : font, fontSize: size),
          ),
          pw.Text(
            "SAR ${amount >= 0 ? amount.toStringAsFixed(2) : '(${(-amount).toStringAsFixed(2)})'}",
            style: pw.TextStyle(
              font: boldFont,
              fontSize: size,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Share PDF
  // Future<void> _sharePdf() async {
  //   try {
  //     final bytes = await _generateModernInvoicePdf();
  //     final dir = await getTemporaryDirectory();
  //     final file = File("${dir.path}/invoice_$docId.pdf");
  //     await file.writeAsBytes(bytes);

  //     await Share.shareXFiles(
  //       [XFile(file.path)],
  //       text: "Invoice #$docId - ${data['name'] ?? 'Customer'}",
  //       subject: "Your Invoice from Your Business",
  //     );
  //   } catch (e) {
  //     print("Error sharing PDF: $e");
  //   }
  // }

  // // Print PDF
  // Future<void> _printPdf() async {
  //   final bytes = await _generateModernInvoicePdf();
  //   await Printing.layoutPdf(onLayout: (_) => bytes);
  // }

  // // Save & Open PDF
  // Future<void> _saveAndOpenPdf() async {
  //   final bytes = await _generateModernInvoicePdf();
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File("${dir.path}/Invoice_$docId.pdf");
  //   await file.writeAsBytes(bytes);
  //   OpenFile.open(file.path);
  // }

  @override
  Widget build(BuildContext context) {
    final balance =
        (data['currentBill'] ?? data['amount'] ?? 0.0) -
        (data['paidNow'] ?? 0.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invoice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
        //     onPressed: () async {
        //       final pdfBytes = await _generatePDFBytes();
        //       await Printing.layoutPdf(onLayout: (format) => pdfBytes);
        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.share, color: Colors.black87),
        //     onPressed: () async {
        //       final pdfBytes = await _generatePDFBytes();
        //       final xFile = XFile.fromData(
        //         pdfBytes,
        //         name: 'invoice_${docId}.pdf',
        //         mimeType: 'application/pdf',
        //       );
        //       await Share.shareXFiles([xFile], text: _generateInvoiceText());
        //     },
        //   ),
        // ],
      ),
      body: Container(
        decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     colors: [
          //       Theme.of(context).primaryColor,
          //       Theme.of(context).primaryColorLight,
          //     ],
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //   ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.teal.withOpacity(0.1),
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
                    final pdfBytes = await _generateModernInvoicePdf();
                    final xFile = XFile.fromData(
                      pdfBytes,
                      name: 'invoice_${data['name'] ?? data['entityName']}.pdf',
                      mimeType: 'application/pdf',
                    );
                    await Share.shareXFiles([
                      xFile,
                    ], text: _generateInvoiceText());
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Invoice PDF'),
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
              SizedBox(height: 16),
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
