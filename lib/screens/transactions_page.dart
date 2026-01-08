import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/provider/language_provider.dart';
import 'package:salesbook/screens/payment_invoice.dart';
import 'invoice_page.dart';

class TransactionsPage extends StatefulWidget {
  final String entityId;
  final String entityType;
  final double currentBalance;

  const TransactionsPage({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.currentBalance,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filterType = 'today';
  DateTime? _startDate;
  DateTime? _endDate;

  // Function to get Malayalam translation for transaction types
  String _getTransactionTypeText(String type, bool isMalayalam) {
    if (!isMalayalam) return type;

    switch (type.toLowerCase()) {
      case 'cash received from vendor':
        return 'വെണ്ടറിൽ നിന്ന് പണം ലഭിച്ചു';
      case 'cash paid to vendor':
        return 'വെണ്ടർക്ക് പണം നൽകി';
      case 'purchase':
        return 'സാധനങ്ങൾ വാങ്ങി';
      case 'cash paid to customer':
        return 'കസ്റ്റമർക്ക് പണം നൽകി';
      case 'cash received from customer':
        return 'കസ്റ്റമറിൽ നിന്ന് പണം ലഭിച്ചു';
      case 'sale':
        return 'സാധനങ്ങൾ വിറ്റു';
      case 'return':
        return 'സാധനങ്ങൾ തിരിച്ചെടുത്തു';
      case 'payment':
        return 'പേയ്മെന്റ്';
      default:
        return type;
    }
  }

  // Function to get Malayalam translation for filter labels
  String _getFilterLabel(String label, bool isMalayalam) {
    if (!isMalayalam) return label;

    switch (label.toLowerCase()) {
      case 'today':
        return 'ഇന്ന്';
      case 'this week':
        return 'ഈ ആഴ്ച';
      case 'this month':
        return 'ഈ മാസം';
      case 'all':
        return 'എല്ലാം';
      case 'custom':
        return 'കസ്റ്റം';
      case 'start date':
        return 'ആരംഭ തീയതി';
      case 'end date':
        return 'അവസാന തീയതി';
      default:
        return label;
    }
  }

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
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.entityType} Transactions',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
          ),
          body: Container(
            child: Column(
              children: [
                _buildFilterChips(lang),
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
                        return Center(
                          child: Text(
                            lang.isMalayalam
                                ? 'തിരഞ്ഞെടുത്ത കാലയളവിൽ ഇടപാടുകളൊന്നുമില്ല'
                                : 'No transactions for the selected period',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }
                      final transactions = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              transactions[index].data()
                                  as Map<String, dynamic>;
                          final docId = transactions[index].id;
                          final date = (transaction['timestamp'] as Timestamp)
                              .toDate();
                          final paymentMethod =
                              transaction['paymentMethod'] != null
                              ? ' - ${transaction['paymentMethod']}'
                              : '';

                          // Get translated transaction type
                          final transactionType = _getTransactionTypeText(
                            transaction['type'],
                            lang.isMalayalam,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.teal.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                '$transactionType$paymentMethod',
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal,
                                ),
                              ),
                              onTap: () {
                                final type = transaction['type']
                                    .toString()
                                    .toLowerCase();

                                // Payment / Cash Transactions
                                if (type.contains('cash') ||
                                    type.contains('payment')) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentInvoicePage(
                                        balance: widget.currentBalance,
                                        transaction: transaction,
                                      ),
                                    ),
                                  );
                                }
                                // Sale / Purchase Invoices
                                else {
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

                                // if (transaction['type'] != 'Payment') {
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => InvoicePage(
                                //         docId: docId,
                                //         data: transaction,
                                //         type: transaction['entityType']
                                //             .toLowerCase(),
                                //       ),
                                //     ),
                                //   );
                                // }
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
      },
    );
  }

  Widget _buildFilterChips(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Today', 'today', lang),
              _buildFilterChip('This Week', 'week', lang),
              _buildFilterChip('This Month', 'month', lang),
              _buildFilterChip('All', 'all', lang),
              _buildFilterChip('Custom', 'custom', lang),
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
                          : _getFilterLabel('Start Date', lang.isMalayalam),
                      style: const TextStyle(color: Colors.white),
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
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yy').format(_endDate!)
                          : _getFilterLabel('End Date', lang.isMalayalam),
                      style: const TextStyle(color: Colors.white),
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

  Widget _buildFilterChip(String label, String value, LanguageProvider lang) {
    return FilterChip(
      label: Text(_getFilterLabel(label, lang.isMalayalam)),
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
