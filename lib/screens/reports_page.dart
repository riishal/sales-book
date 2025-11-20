import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'invoice_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
            Tab(text: 'Returns'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTransactionList(null),
            _buildTransactionList('Sale'),
            _buildTransactionList('Purchase'),
            _buildTransactionList('Return'),
            _buildTransactionList('Payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(String? type) {
    Query query = FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true);
    if (type != null) {
      if (type == 'Payments') {
        query = query.where('type', whereIn: ['Payment', 'Purchase']);
      } else {
        query = query.where('type', isEqualTo: type);
      }
    }

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No transactions found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        final transactions = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index].data() as Map<String, dynamic>;
            final docId = transactions[index].id;
            final date = (transaction['timestamp'] as Timestamp).toDate();
            final paymentMethod = transaction['paymentMethod'] != null ? ' - ${transaction['paymentMethod']}' : '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  transaction['entityName'] ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${transaction['type']}$paymentMethod - ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  '﷼${transaction['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  if (transaction['type'] != 'Payment') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoicePage(
                          docId: docId,
                          data: transaction,
                          type: transaction['entityType'].toLowerCase(),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
