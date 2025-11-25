import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'customer_list_page.dart';
import 'vendor_list_page.dart';
import 'product_list_page.dart';
import 'reports_page.dart';
import 'investor_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filterType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  Query _getFilteredTransactionsQuery(String collectionName) {
    Query query = FirebaseFirestore.instance.collection(collectionName);
    final now = DateTime.now();

    switch (_filterType) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return query.where(
          'timestamp',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
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
          return query.where(
            'timestamp',
            isGreaterThanOrEqualTo: start,
            isLessThanOrEqualTo: end,
          );
        }
        return query.where(
          'timestamp',
          isNull: true,
        ); // No data for invalid range
      default: // 'all'
        return query;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Dashboard'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(),
            const SizedBox(height: 24),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, customerSnapshot) {
                return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('vendors')
                      .snapshots(),
                  builder: (context, vendorSnapshot) {
                    return StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('investors')
                          .snapshots(),
                      builder: (context, investorSnapshot) {
                        return StreamBuilder(
                          stream: _getFilteredTransactionsQuery(
                            'transactions',
                          ).snapshots(),
                          builder: (context, transactionSnapshot) {
                            double totalReceivable = 0;
                            double totalPayable = 0;
                            double totalInvested = 0;
                            double netChange = 0;

                            if (customerSnapshot.hasData) {
                              for (var doc in customerSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                totalReceivable +=
                                    (data['currentBill'] ?? 0.0) -
                                    (data['paidNow'] ?? 0.0);
                              }
                            }
                            if (vendorSnapshot.hasData) {
                              for (var doc in vendorSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                totalPayable +=
                                    (data['currentBill'] ?? 0.0) -
                                    (data['paidNow'] ?? 0.0);
                              }
                            }
                            if (investorSnapshot.hasData) {
                              for (var doc in investorSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                totalInvested += data['amount'] ?? 0.0;
                              }
                            }
                            if (transactionSnapshot.hasData) {
                              for (var doc in transactionSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (data['entityType'] == 'Customer') {
                                  netChange += (data['paidNow'] ?? 0.0);
                                } else if (data['entityType'] == 'Vendor') {
                                  netChange -= (data['paidNow'] ?? 0.0);
                                }
                              }
                            }

                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                _buildStatCard(
                                  'Net Change',
                                  '﷼${netChange.toStringAsFixed(2)}',
                                  Icons.account_balance,
                                  Colors.teal,
                                ),
                                _buildStatCard(
                                  'Receivable',
                                  '﷼${totalReceivable.toStringAsFixed(2)}',
                                  Icons.arrow_downward,
                                  Colors.green,
                                ),
                                _buildStatCard(
                                  'Payable',
                                  '﷼${totalPayable.toStringAsFixed(2)}',
                                  Icons.arrow_upward,
                                  Colors.red,
                                ),
                                _buildStatCard(
                                  'Invested',
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
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Features', style: Theme.of(context).textTheme.titleLarge),
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
    );
  }

  Widget _buildFilterChips() {
    return Column(
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
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate != null
                        ? DateFormat('dd/MM/yy').format(_startDate!)
                        : 'Start Date',
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
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _endDate != null
                        ? DateFormat('dd/MM/yy').format(_endDate!)
                        : 'End Date',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
          if (value != 'custom') {
            _startDate = null;
            _endDate = null;
          }
        });
      },
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor
          : Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
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
