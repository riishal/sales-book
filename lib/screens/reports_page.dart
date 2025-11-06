import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String filterType = 'all';
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Today', 'today'),
                      _buildFilterChip('Month', 'month'),
                      _buildFilterChip('Custom', 'custom'),
                    ],
                  ),
                  if (filterType == 'custom') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) setState(() => startDate = date);
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              startDate != null
                                  ? DateFormat('dd/MM/yy').format(startDate!)
                                  : 'Start Date',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) setState(() => endDate = date);
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              endDate != null
                                  ? DateFormat('dd/MM/yy').format(endDate!)
                                  : 'End Date',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('customers')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, customerSnapshot) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('vendors')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, vendorSnapshot) {
                      if (customerSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          vendorSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
                      }
                      if (customerSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${customerSnapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      if (vendorSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${vendorSnapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      if ((!customerSnapshot.hasData ||
                              customerSnapshot.data!.docs.isEmpty) &&
                          (!vendorSnapshot.hasData ||
                              vendorSnapshot.data!.docs.isEmpty)) {
                        return const Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      List<Map<String, dynamic>> allTransactions = [];
                      if (customerSnapshot.hasData) {
                        for (var doc in customerSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp?;
                          if (timestamp != null && _shouldInclude(timestamp)) {
                            allTransactions.add({
                              'type': 'Customer',
                              'name': data['name'],
                              'amount': data['paidNow'],
                              'timestamp': timestamp,
                              'balance': data['currentBill'] - data['paidNow'],
                            });
                          }
                        }
                      }
                      if (vendorSnapshot.hasData) {
                        for (var doc in vendorSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp?;
                          if (timestamp != null && _shouldInclude(timestamp)) {
                            allTransactions.add({
                              'type': 'Vendor',
                              'name': data['name'],
                              'amount': data['paidNow'],
                              'timestamp': timestamp,
                              'balance': data['currentBill'] - data['paidNow'],
                            });
                          }
                        }
                      }
                      allTransactions.sort(
                        (a, b) => b['timestamp'].compareTo(a['timestamp']),
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = allTransactions[index];
                          final date = transaction['timestamp'].toDate();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  transaction['type'] == 'Customer'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: transaction['type'] == 'Customer'
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                              title: Text(
                                transaction['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${transaction['type']} - ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                '﷼${transaction['amount'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: transaction['type'] == 'Customer'
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Balance: ﷼${transaction['balance'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      selected: filterType == value,
      onSelected: (selected) {
        setState(() {
          filterType = value;
          if (value != 'custom') {
            startDate = null;
            endDate = null;
          }
        });
      },
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Colors.white.withOpacity(0.3),
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  bool _shouldInclude(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    switch (filterType) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'custom':
        if (startDate != null && endDate != null) {
          final start = DateTime(
            startDate!.year,
            startDate!.month,
            startDate!.day,
          );
          final end = DateTime(
            endDate!.year,
            endDate!.month,
            endDate!.day,
            23,
            59,
            59,
          );
          return date.isAfter(
                start.subtract(const Duration(microseconds: 1)),
              ) &&
              date.isBefore(end.add(const Duration(microseconds: 1)));
        }
        return false;
      default:
        return true;
    }
  }
}
