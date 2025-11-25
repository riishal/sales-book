import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'invoice_page.dart';

class TransactionsPage extends StatefulWidget {
  final String entityId;
  final String entityType;

  const TransactionsPage({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filterType = 'today';
  DateTime? _startDate;
  DateTime? _endDate;

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = FirebaseFirestore.instance
        .collection('transactions')
        .where('entityId', isEqualTo: widget.entityId)
        .orderBy('timestamp', descending: true);

    final now = DateTime.now();
    switch (_filterType) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return query
            .where('timestamp', isGreaterThanOrEqualTo: start, isLessThan: end)
            .snapshots();
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return query
            .where('timestamp', isGreaterThanOrEqualTo: start, isLessThan: end)
            .snapshots();
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return query
            .where('timestamp', isGreaterThanOrEqualTo: start, isLessThan: end)
            .snapshots();
      case 'custom':
        if (_startDate != null && _endDate != null) {
          final start = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final end = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          return query
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: start,
                isLessThanOrEqualTo: end,
              )
              .snapshots();
        }
        return FirebaseFirestore.instance
            .collection('transactions')
            .where('timestamp', isNull: true)
            .snapshots();
      default: // 'all'
        return query.snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.entityType} Transactions',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Theme.of(context).primaryColor,
        //       Theme.of(context).primaryColorLight,
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: StreamBuilder(
                stream: _getFilteredStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black87,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions for the selected period',
                        style: TextStyle(color: Colors.black87),
                      ),
                    );
                  }
                  final transactions = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          transactions[index].data() as Map<String, dynamic>;
                      final docId = transactions[index].id;
                      final date = (transaction['timestamp'] as Timestamp)
                          .toDate();
                      final paymentMethod = transaction['paymentMethod'] != null
                          ? ' - ${transaction['paymentMethod']}'
                          : '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.teal.withOpacity(0.2)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            '${transaction['type']}$paymentMethod',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: Text(
                            '﷼${(transaction['amount'] as num).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  transaction['type'] == 'Sale' ||
                                      transaction['type'] == 'Payment'
                                  ? Colors.green
                                  : Colors.redAccent,
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
                                    type: transaction['entityType']
                                        .toLowerCase(),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Today', 'today'),
              _buildFilterChip('This Week', 'week'),
              _buildFilterChip('This Month', 'month'),
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Custom', 'custom'),
            ],
          ),
          if (_filterType == 'custom') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    icon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yy').format(_startDate!)
                          : 'Start Date',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yy').format(_endDate!)
                          : 'End Date',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filterType == value,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
          if (value != 'custom') {
            _startDate = null;
            _endDate = null;
          }
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.teal.withOpacity(0.2),
      checkmarkColor: Colors.teal,
      labelStyle: TextStyle(
        color: _filterType == value ? Colors.teal : Colors.black87,
      ),
    );
  }
}
