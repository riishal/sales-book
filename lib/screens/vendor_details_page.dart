import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/provider/language_provider.dart';
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

  const VendorDetailsPage({
    super.key,
    required this.docId,
    required this.vendorData,
  });

  @override
  Widget build(BuildContext context) {
    final balance =
        (vendorData['currentBill'] ?? 0.0) - (vendorData['paidNow'] ?? 0.0);

    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        final String balanceText;
        final Color balanceColor;
        if (balance > 0) {
          balanceText = lang.isMalayalam
              ? 'നിങ്ങൾക്ക് കൊടുക്കാനുള്ളത്: '
              : 'You will pay: ';
          balanceColor = Colors.red;
        } else if (balance < 0) {
          balanceText = lang.isMalayalam
              ? 'നിങ്ങൾക്ക് കിട്ടാനുള്ളത്: '
              : 'You will get: ';
          balanceColor = Colors.green;
        } else {
          balanceText = lang.isMalayalam
              ? 'കിട്ടാനോ കൊടുക്കാനോ ഇല്ല'
              : 'Settled';
          balanceColor = Colors.teal;
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(vendorData['name']),
            titleTextStyle: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              Consumer<LanguageProvider>(
                builder: (context, lang, _) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          lang.toggleLanguage();
                        },
                        child: Text(
                          lang.isMalayalam ? 'E' : 'മ',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard('Phone', vendorData['phone'], Icons.phone, null),
              _buildInfoCard(
                balanceText,
                '﷼${balance.abs().toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                balanceColor,
              ),
              const SizedBox(height: 20),
              _buildActionGrid(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color? color,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final balance =
        (vendorData['currentBill'] ?? 0.0) - (vendorData['paidNow'] ?? 0.0);
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
            MaterialPageRoute(
              builder: (_) =>
                  AddVendorPage(docId: docId, existingData: vendorData),
            ),
          );
        }),
        _buildFeatureCard(context, 'Transactions', Icons.history, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TransactionsPage(entityId: docId, entityType: 'Vendor'),
            ),
          );
        }),
        _buildFeatureCard(context, 'Edit', Icons.edit, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddVendorPage(
                docId: docId,
                existingData: vendorData,
                isEdit: true,
              ),
            ),
          );
        }),
        _buildFeatureCard(context, 'Pay/Get', Icons.payment, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                docId: docId,
                type: 'vendors',
                currentBalance: balance,
              ),
            ),
          );
        }),
        _buildFeatureCard(context, 'Delete', Icons.delete, () async {
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(docId)
              .delete();
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
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
