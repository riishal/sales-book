import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePage extends StatefulWidget {
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
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  late String _suggestedFileName;

  @override
  void initState() {
    super.initState();
    _prepareFileName();
    _generatePdf();
  }

  void _prepareFileName() {
    final customerName =
        (widget.data['name'] ?? widget.data['entityName'] ?? 'Customer')
            .toString()
            .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove invalid file chars
            .trim()
            .replaceAll(' ', '_');

    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _suggestedFileName = '${customerName}_Invoice_$dateStr.pdf';
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _generateInvoicePdf();
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  // ===================== CALCULATIONS =====================
  Map<String, double> _calculateTotals() {
    final products = List<Map<String, dynamic>>.from(
      widget.data['products'] ?? [],
    );

    double subtotal = 0;
    double totalQty = 0;

    for (final p in products) {
      final rate = (p['rate'] as num?)?.toDouble() ?? 0;
      final qty = (p['qty'] as num?)?.toDouble() ?? 0;
      subtotal += rate * qty;
      totalQty += qty;
    }

    final additionalCharge =
        (widget.data['additionalCharge'] as num?)?.toDouble() ?? 0;
    final discount = (widget.data['discount'] as num?)?.toDouble() ?? 0;
    final taxPercent = (widget.data['tax'] as num?)?.toDouble() ?? 0;
    final previousBalance =
        (widget.data['previousBalance'] as num?)?.toDouble() ?? 0;
    final paidNow = (widget.data['paidNow'] as num?)?.toDouble() ?? 0;

    final taxAmount = subtotal * (taxPercent / 100);
    final grandTotal =
        subtotal + additionalCharge - discount + taxAmount + previousBalance;
    final balance = grandTotal - paidNow;

    return {
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'balance': balance,
      'totalQty': totalQty,
    };
  }

  // ===================== PDF =====================
  Future<Uint8List> _generateInvoicePdf() async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final totals = _calculateTotals();

    final products = List<Map<String, dynamic>>.from(
      widget.data['products'] ?? [],
    );

    final rows = products.asMap().entries.map((e) {
      final p = e.value;
      final rate = (p['rate'] ?? 0).toDouble();
      final qty = (p['qty'] ?? 0).toDouble();
      return [
        (e.key + 1).toString(),
        p['name'].toString(),
        qty.toInt().toString(),
        rate.toStringAsFixed(2),
        (rate * qty).toStringAsFixed(2),
      ];
    }).toList();

    final taxPercent = (widget.data['tax'] as num?)?.toDouble() ?? 0;
    final totalItems = totals['totalQty']!.toInt();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // HEADER
          pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 32,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bill To', style: pw.TextStyle(font: boldFont)),
                  pw.Text(
                    widget.data['name'] ??
                        widget.data['entityName'] ??
                        'Customer',
                    style: pw.TextStyle(font: font),
                  ),
                  if (widget.data['phone'] != null)
                    pw.Text(
                      'Phone: ${widget.data['phone']}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                ],
              ),
              pw.Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: pw.TextStyle(font: font),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // TABLE
          pw.Table.fromTextArray(
            headers: ['No', 'Item', 'Qty', 'Rate', 'Amount'],
            data: rows,
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: pw.TextStyle(font: font),
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),

          pw.SizedBox(height: 20),

          // TOTALS
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              child: pw.Column(
                children: [
                  _summaryRow('Subtotal', totals['subtotal']!, font, boldFont),
                  // _summaryRow(
                  //   'Tax (${taxPercent.toStringAsFixed(0)}%)',
                  //   totals['taxAmount']!,
                  //   font,
                  //   boldFont,
                  // ),
                  // New separate row for total items
                  _summaryRow(
                    'Total Items',
                    totalItems.toDouble(),
                    font,
                    boldFont,
                    bold: true,
                  ),
                  pw.Divider(),
                  _summaryRow(
                    'Total',
                    totals['grandTotal']!,
                    font,
                    boldFont,
                    bold: true,
                  ),
                  _summaryRow(
                    'Paid Now',
                    (widget.data['paidNow'] ?? 0).toDouble(),
                    font,
                    boldFont,
                  ),
                  pw.Divider(),
                  _summaryRow(
                    'Balance',
                    totals['balance']!,
                    font,
                    boldFont,
                    bold: true,
                    color: totals['balance']! > 0
                        ? PdfColors.red
                        : PdfColors.green,
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(font: font, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===================== SHARE =====================
  Future<void> shareInvoice() async {
    if (_pdfBytes == null) return;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$_suggestedFileName';
    final file = File(filePath);

    await file.writeAsBytes(_pdfBytes!);

    await Share.shareXFiles(
      [XFile(filePath)],
      fileNameOverrides: [_suggestedFileName],
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _generatePdf),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (_) => _pdfBytes!,
              allowPrinting: true,
              allowSharing: true,
              // Optional: suggested file name when downloading/printing via the preview
              pdfFileName: _suggestedFileName,
            ),
      floatingActionButton: _pdfBytes == null
          ? null
          : FloatingActionButton.extended(
              onPressed: shareInvoice,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
    );
  }

  // ===================== HELPERS =====================
  pw.Widget _summaryRow(
    String label,
    double value,
    pw.Font font,
    pw.Font boldFont, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold ? boldFont : font)),
          pw.Text(
            value % 1 == 0
                ? '${value.toInt()}'
                : 'SAR ${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              font: boldFont,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
