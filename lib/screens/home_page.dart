import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_list_page.dart';
import 'vendor_list_page.dart';
import 'product_list_page.dart';
import 'reports_page.dart';
import 'investor_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: false,
        elevation: 0,
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
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('customers').snapshots(),
                builder: (context, customerSnapshot) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
                    builder: (context, vendorSnapshot) {
                      return StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('investors').snapshots(),
                        builder: (context, investorSnapshot) {
                          double totalReceivable = 0;
                          double totalPayable = 0;
                          double totalInvested = 0;

                          if (customerSnapshot.hasData) {
                            for (var doc in customerSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              totalReceivable += (data['currentBill'] ?? 0.0) - (data['paidNow'] ?? 0.0);
                            }
                          }
                          if (vendorSnapshot.hasData) {
                            for (var doc in vendorSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              totalPayable += (data['currentBill'] ?? 0.0) - (data['paidNow'] ?? 0.0);
                            }
                          }
                          if (investorSnapshot.hasData) {
                            for (var doc in investorSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              totalInvested += data['amount'] ?? 0.0;
                            }
                          }

                          double totalBalance = totalReceivable - totalPayable - totalInvested;

                          return Column(
                            children: [
                              _buildStatCard(
                                'Total Balance',
                                '﷼${totalBalance.toStringAsFixed(2)}',
                                Icons.account_balance,
                                Colors.purple,
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                'Receivable from Customers',
                                '﷼${totalReceivable.toStringAsFixed(2)}',
                                Icons.arrow_downward,
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                'Payable to Vendors',
                                '﷼${totalPayable.toStringAsFixed(2)}',
                                Icons.arrow_upward,
                                Colors.red,
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                'Payable to Investors',
                                '﷼${totalInvested.toStringAsFixed(2)}',
                                Icons.business_center,
                                Colors.orange,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Customers',
                    Icons.people,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerListPage()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Vendors',
                    Icons.store,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorListPage()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Products',
                    Icons.inventory_2,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductListPage()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Investors',
                    Icons.business_center,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvestorListPage()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Reports',
                    Icons.analytics,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
