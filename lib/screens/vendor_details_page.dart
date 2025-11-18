import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_vendor_page.dart';
import 'transactions_page.dart';
import 'payment_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class VendorDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> vendorData;

  const VendorDetailsPage({super.key, required this.docId, required this.vendorData});

  Future<void> _shareSummary(BuildContext context) async {
    final balance = (vendorData['currentBill'] ?? 0.0) - (vendorData['paidNow'] ?? 0.0);
    final summary = '''
      Vendor Summary
      -----------------
      Name: ${vendorData['name']}
      Phone: ${vendorData['phone']}
      Balance: ﷼${balance.toStringAsFixed(2)}
    ''';
    await Share.share(summary);
  }

  Future<void> _printSummary(BuildContext context) async {
    final pdf = pw.Document();
    final balance = (vendorData['currentBill'] ?? 0.0) - (vendorData['paidNow'] ?? 0.0);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Vendor Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Name: ${vendorData['name']}'),
            pw.Text('Phone: ${vendorData['phone']}'),
            pw.Text('Balance: riyal ${balance.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = (vendorData['currentBill'] ?? 0.0) - (vendorData['paidNow'] ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(vendorData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareSummary(context),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () => _printSummary(context),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard('Phone', vendorData['phone'], Icons.phone),
            _buildInfoCard('Balance', '﷼${balance.toStringAsFixed(2)}', Icons.account_balance_wallet),
            const SizedBox(height: 20),
            _buildActionGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.white, size: 40),
        title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(context, 'New Purchase', Icons.add_shopping_cart, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVendorPage(docId: docId, existingData: vendorData)),
          );
        }),
        _buildFeatureCard(context, 'Pay Cash', Icons.payment, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentPage(entityId: docId, entityType: 'Vendor')),
          );
        }),
        _buildFeatureCard(context, 'Transactions', Icons.history, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TransactionsPage(entityId: docId, entityType: 'Vendor')),
          );
        }),
        _buildFeatureCard(context, 'Edit', Icons.edit, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVendorPage(docId: docId, existingData: vendorData, isEdit: true)),
          );
        }),
        _buildFeatureCard(context, 'Delete', Icons.delete, () async {
          await FirebaseFirestore.instance.collection('vendors').doc(docId).delete();
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
