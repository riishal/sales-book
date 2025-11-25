import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'invoice_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black87,
          indicatorColor: Colors.black87,
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
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Today', 'today'),
              _buildFilterChip('This Week', 'week'),
              _buildFilterChip('This Month', 'month'),
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
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
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
                    icon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yy').format(_endDate!)
                          : 'End Date',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
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
      backgroundColor: Colors.black87.withOpacity(0.2),
      selectedColor: Colors.black87,
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: _filterType == value
            ? Theme.of(context).primaryColor
            : Colors.black87,
      ),
    );
  }

  Widget _buildTransactionList(String? type) {
    Query query = FirebaseFirestore.instance
        .collection('transactions')
        .orderBy('timestamp', descending: true);
    if (type != null) {
      if (type == 'Payments') {
        query = query.where('type', whereIn: ['Payment', 'Purchase']);
      } else {
        query = query.where('type', isEqualTo: type);
      }
    }

    final now = DateTime.now();
    switch (_filterType) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
        break;
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 7));
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
        break;
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
        break;
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
          query = query.where(
            'timestamp',
            isGreaterThanOrEqualTo: start,
            isLessThanOrEqualTo: end,
          );
        } else {
          query = query.where(
            'timestamp',
            isNull: true,
          ); // No data for invalid range
        }
        break;
      default: // 'all'
        break;
    }

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
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
              'No transactions found',
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
            final date = (transaction['timestamp'] as Timestamp).toDate();
            final paymentMethod = transaction['paymentMethod'] != null
                ? ' - ${transaction['paymentMethod']}'
                : '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.black87.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.black87.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  transaction['entityName'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${transaction['type']}$paymentMethod - ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}',
                  style: const TextStyle(color: Colors.black87),
                ),
                trailing: Text(
                  '﷼${transaction['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
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
