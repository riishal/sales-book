import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_customer_page.dart';
import 'transactions_page.dart';
import 'payment_page.dart';
import 'return_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> customerData;

  const CustomerDetailsPage({super.key, required this.docId, required this.customerData});

  Future<void> _shareSummary(BuildContext context) async {
    final balance = (customerData['currentBill'] ?? 0.0) - (customerData['paidNow'] ?? 0.0);
    final summary = '''
      Customer Summary
      -----------------
      Name: ${customerData['name']}
      Phone: ${customerData['phone']}
      Balance: ﷼${balance.toStringAsFixed(2)}
    ''';
    await Share.share(summary);
  }

  Future<void> _printSummary(BuildContext context) async {
    final pdf = pw.Document();
    final balance = (customerData['currentBill'] ?? 0.0) - (customerData['paidNow'] ?? 0.0);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Customer Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Name: ${customerData['name']}'),
            pw.Text('Phone: ${customerData['phone']}'),
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
    final balance = (customerData['currentBill'] ?? 0.0) - (customerData['paidNow'] ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(customerData['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSummary(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printSummary(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard('Phone', customerData['phone'], Icons.phone),
          _buildInfoCard('Balance', '﷼${balance.toStringAsFixed(2)}', Icons.account_balance_wallet),
          const SizedBox(height: 20),
          _buildActionGrid(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final balance = (customerData['currentBill'] ?? 0.0) - (customerData['paidNow'] ?? 0.0);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(context, 'New Sale', Icons.add_shopping_cart, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCustomerPage(docId: docId, existingData: customerData)),
          );
        }),
        _buildFeatureCard(context, 'Customer Return', Icons.undo, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReturnPage(entityId: docId)),
          );
        }),
        _buildFeatureCard(context, 'Transactions', Icons.history, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TransactionsPage(entityId: docId, entityType: 'Customer')),
          );
        }),
        _buildFeatureCard(context, 'Edit', Icons.edit, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCustomerPage(docId: docId, existingData: customerData, isEdit: true)),
          );
        }),
        _buildFeatureCard(context, 'Cash Transaction', Icons.payment, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                docId: docId,
                type: 'customers',
                currentBalance: balance,
              ),
            ),
          );
        }),
        _buildFeatureCard(context, 'Delete', Icons.delete, () async {
          await FirebaseFirestore.instance.collection('customers').doc(docId).delete();
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
