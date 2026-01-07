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
    double totalQty = 0.0;

    for (final p in products) {
      final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
      subtotal += rate * qty;
      totalQty += qty;
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
      'totalQty': totalQty,
    };
  }

  // 🔹 PDF GENERATION - FIXED FOR MULTI-PAGE
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

    // Prepare product data for tables
    final productRows = products.asMap().entries.map((entry) {
      final index = entry.key;
      final p = entry.value;
      final rate = (p['rate'] ?? 0).toDouble();
      final qty = (p['qty'] ?? 0).toDouble();
      final amount = rate * qty;
      return [
        (index + 1).toString(),
        p['name'].toString(),
        qty.toInt().toString(),
        rate.toStringAsFixed(2),
        amount.toStringAsFixed(2),
      ];
    }).toList();

    // Create header widget
    pw.Widget _buildHeader() {
      return pw.Column(
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
                  // if (widget.docId.isNotEmpty)
                  //   pw.Text(
                  //     'Invoice #: ${widget.docId}',
                  //     style: pw.TextStyle(font: font, fontSize: 10),
                  //   ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
      );
    }

    // Create footer widget
    pw.Widget _buildFooter() {
      return pw.Column(
        children: [
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  _summaryRow('Subtotal', totals['subtotal']!, font, boldFont),
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
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Items',
                          style: pw.TextStyle(font: boldFont, fontSize: 12),
                        ),
                        pw.Text(
                          '${totals['totalQty']!.toInt()} pcs',
                          style: pw.TextStyle(font: boldFont, fontSize: 12),
                        ),
                      ],
                    ),
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
      );
    }

    // Build pages based on product count
    const maxRowsPerPage = 15; // Adjust based on your layout
    final totalPages = (productRows.length / maxRowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * maxRowsPerPage;
      final endIndex = (startIndex + maxRowsPerPage) < productRows.length
          ? (startIndex + maxRowsPerPage)
          : productRows.length;

      final currentPageRows = productRows.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header for first page only
                if (pageIndex == 0) _buildHeader(),

                // Product table
                pw.Table.fromTextArray(
                  headers: ['No.', 'Item', 'Qty', 'Rate', 'Amount'],
                  data: currentPageRows,
                  headerStyle: pw.TextStyle(
                    font: boldFont,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
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

                // Footer for last page only
                if (pageIndex == totalPages - 1) ...[
                  pw.SizedBox(height: 20),
                  _buildFooter(),
                ] else ...[
                  // Show "Continued on next page" for intermediate pages
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Continued on next page...',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  // Page number
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Page ${pageIndex + 1} of $totalPages',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

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
    final docId = widget.docId.isNotEmpty ? '_${widget.docId}' : '';

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
            PdfPreview(
              build: (format) => _pdfBytes!,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: _invoiceFileName(),
              onShared: (context) async {
                await shareInvoice();
                return;
              },
            )
          else
            const Center(child: Text('Failed to generate PDF')),

          // Share Button (Bottom Right)
          if (!_isLoading && _pdfBytes != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: SizedBox(
                width: 300,
                child: FloatingActionButton.extended(
                  onPressed: shareInvoice,
                  backgroundColor: Colors.green,
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
