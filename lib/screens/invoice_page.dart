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
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _generatePdf();
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

  // 🔹 SINGLE SOURCE OF TRUTH
  Map<String, double> _calculateTotals() {
    final products = List<Map<String, dynamic>>.from(
      widget.data['products'] ?? [],
    );

    double subtotal = 0.0;
    for (final p in products) {
      final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
      subtotal += rate * qty;
    }

    final additionalCharge =
        (widget.data['additionalCharge'] as num?)?.toDouble() ?? 0.0;
    final discount = (widget.data['discount'] as num?)?.toDouble() ?? 0.0;
    final taxPercent = (widget.data['tax'] as num?)?.toDouble() ?? 0.0;
    final previousBalance =
        (widget.data['previousBalance'] as num?)?.toDouble() ?? 0.0;
    final paidNow = (widget.data['paidNow'] as num?)?.toDouble() ?? 0.0;

    final taxAmount = subtotal * (taxPercent / 100);
    final grandTotal =
        subtotal + additionalCharge - discount + taxAmount + previousBalance;
    final balance = grandTotal - paidNow;

    return {
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'balance': balance,
    };
  }

  // 🔹 SHARE TEXT
  String _generateInvoiceText() {
    final totals = _calculateTotals();

    final productsText = (widget.data['products'] as List? ?? [])
        .map((p) {
          final rate = (p['rate'] ?? 0).toDouble();
          final qty = (p['qty'] ?? 0).toDouble();
          final total = rate * qty;
          return '${p['name']} x ${qty.toInt()} - SAR ${total.toStringAsFixed(2)}';
        })
        .join('\n');

    return '''
INVOICE
---------------------
Name: ${widget.data['name'] ?? widget.data['entityName']}
Phone: ${widget.data['phone'] ?? 'N/A'}
Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}

Products:
$productsText
---------------------
Subtotal: SAR ${totals['subtotal']!.toStringAsFixed(2)}
Additional Charge: SAR ${(widget.data['additionalCharge'] ?? 0).toStringAsFixed(2)}
Discount: SAR ${(widget.data['discount'] ?? 0).toStringAsFixed(2)}
Tax: ${(widget.data['tax'] ?? 0)}%
Previous Balance: SAR ${(widget.data['previousBalance'] ?? 0).toStringAsFixed(2)}

TOTAL: SAR ${totals['grandTotal']!.toStringAsFixed(2)}
Paid Now: SAR ${(widget.data['paidNow'] ?? 0).toStringAsFixed(2)}
BALANCE: SAR ${totals['balance']!.toStringAsFixed(2)}
''';
  }

  // 🔹 PDF GENERATION
  Future<Uint8List> _generateInvoicePdf() async {
    final pdf = pw.Document(
      title:
          'Invoice_${widget.data['name'] ?? widget.data['entityName'] ?? ''}.pdf',
    );
    final totals = _calculateTotals();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final products = List<Map<String, dynamic>>.from(
      widget.data['products'] ?? [],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 32,
                    color: PdfColors.teal700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                    pw.Text(
                      widget.data['name'] ??
                          widget.data['entityName'] ??
                          'Customer',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    if (widget.data['phone'] != null)
                      pw.Text(
                        'Phone: ${widget.data['phone']}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    // pw.Text(
                    //   'Invoice #: ${widget.docId}',
                    //   style: pw.TextStyle(font: font, fontSize: 10),
                    // ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: ['No.', 'Item', 'Qty', 'Rate', 'Amount'],
            data: products.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final rate = (p['rate'] ?? 0).toDouble();
              final qty = (p['qty'] ?? 0).toDouble();
              final amount = rate * qty;
              return [
                (index + 1).toString(),
                p['name'],
                qty.toInt().toString(),
                rate.toStringAsFixed(2),
                amount.toStringAsFixed(2),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: pw.TextStyle(font: font),
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
          ),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _summaryRow(
                      'Subtotal',
                      totals['subtotal']!,
                      font,
                      boldFont,
                    ),
                    if ((widget.data['additionalCharge'] ?? 0) > 0)
                      _summaryRow(
                        'Additional Charge',
                        (widget.data['additionalCharge'] ?? 0).toDouble(),
                        font,
                        boldFont,
                      ),
                    if ((widget.data['discount'] ?? 0) > 0)
                      _summaryRow(
                        'Discount',
                        (widget.data['discount'] ?? 0).toDouble(),
                        font,
                        boldFont,
                        color: PdfColors.red,
                      ),
                    _summaryRow(
                      'Tax (${widget.data['tax'] ?? 0}%)',
                      totals['taxAmount']!,
                      font,
                      boldFont,
                    ),
                    if ((widget.data['previousBalance'] ?? 0) > 0)
                      _summaryRow(
                        'Previous Balance',
                        (widget.data['previousBalance'] ?? 0).toDouble(),
                        font,
                        boldFont,
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
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.25).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.25).clamp(0.5, 3.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
    });
  }

  Future<void> shareInvoice() async {
    if (_pdfBytes == null) return;

    try {
      final fileName = _invoiceFileName();

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(_pdfBytes!, flush: true);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Invoice - $fileName',
        subject: 'Invoice $fileName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing invoice: $e')));
      }
    }
  }

  String _safeFileName(String name) {
    return name.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  String _invoiceFileName() {
    final customerName = _safeFileName(
      widget.data['name'] ?? widget.data['entityName'] ?? 'Customer',
    );

    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());

    return '${customerName}_$date.pdf';
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Preview
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating invoice...'),
                ],
              ),
            )
          else if (_pdfBytes != null)
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: PdfPreview(
                build: (format) => _pdfBytes!,
                allowPrinting: true,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName:
                    'invoice_${widget.data['name'] ?? widget.data['entityName'] ?? ''}.pdf',
              ),
            )
          else
            const Center(child: Text('Failed to generate PDF')),

          // Zoom Controls (Bottom Left)
          if (!_isLoading && _pdfBytes != null)
            // Positioned(
            //   bottom: 16,
            //   left: 16,
            //   child: Card(
            //     elevation: 4,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Padding(
            //       padding: const EdgeInsets.all(4),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           IconButton(
            //             icon: const Icon(Icons.zoom_out),
            //             onPressed: _zoomOut,
            //             tooltip: 'Zoom Out',
            //           ),
            //           Text(
            //             '${(_scale * 100).toInt()}%',
            //             style: const TextStyle(fontWeight: FontWeight.bold),
            //           ),
            //           IconButton(
            //             icon: const Icon(Icons.zoom_in),
            //             onPressed: _zoomIn,
            //             tooltip: 'Zoom In',
            //           ),
            //           const VerticalDivider(),
            //           IconButton(
            //             icon: const Icon(Icons.refresh),
            //             onPressed: _resetZoom,
            //             tooltip: 'Reset Zoom',
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // Share Button (Bottom Right)
            if (!_isLoading && _pdfBytes != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 300,
                  child: FloatingActionButton.extended(
                    onPressed: shareInvoice,
                    backgroundColor: Colors.teal,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ),
        ],
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
          pw.Text(
            label,
            style: pw.TextStyle(font: bold ? boldFont : font, fontSize: 12),
          ),
          pw.Text(
            'SAR ${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
