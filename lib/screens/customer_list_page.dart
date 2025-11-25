import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_customer_page.dart';
import 'customer_details_page.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No customers yet',
              ),
            );
          }
          final customers = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index].data() as Map<String, dynamic>;
              final docId = customers[index].id;
              final balance =
                  (customer['currentBill'] ?? 0.0) -
                      (customer['paidNow'] ?? 0.0);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      customer['name'][0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['phone'],
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final String balanceText;
                          final Color balanceColor;
                          if (balance > 0) {
                            balanceText = 'You will get: ﷼${balance.toStringAsFixed(2)}';
                            balanceColor = Colors.green;
                          } else if (balance < 0) {
                            balanceText = 'You will pay: ﷼${(-balance).toStringAsFixed(2)}';
                            balanceColor = Colors.red;
                          } else {
                            balanceText = 'Settled';
                            balanceColor = Colors.grey;
                          }
                          return Text(
                            balanceText,
                            style: TextStyle(
                              color: balanceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailsPage(docId: docId, customerData: customer),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
