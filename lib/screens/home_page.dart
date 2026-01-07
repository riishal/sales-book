// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/provider/connectivity_provider.dart';
import 'package:salesbook/provider/language_provider.dart';
import '../l10n/app_localizations.dart';

import 'customer_list_page.dart';
import 'vendor_list_page.dart';
import 'product_list_page.dart';
import 'reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filterType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  Query _getFilteredQuery() {
    Query query = FirebaseFirestore.instance.collection('transactions');
    final now = DateTime.now();

    switch (_filterType) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return query.where('timestamp', isGreaterThanOrEqualTo: start);
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return query.where('timestamp', isGreaterThanOrEqualTo: start);
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        return query.where('timestamp', isGreaterThanOrEqualTo: start);
      case 'custom':
        if (_startDate != null && _endDate != null) {
          final end = _endDate!.add(const Duration(days: 1));
          return query.where(
            'timestamp',
            isGreaterThanOrEqualTo: _startDate,
            isLessThan: end,
          );
        }
        return query.where('timestamp', isNull: true);
      default:
        return query;
    }
  }

  bool _isNetworkAlertShowing = false;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final connectivityProvider = Provider.of<ConnectivityProvider>(context);
  //   connectivityProvider.addListener(_handleConnectivityChange);
  //   _handleConnectivityChange(); // Initial check
  // }

  // void _handleConnectivityChange() {
  //   final connectivityProvider =
  //       Provider.of<ConnectivityProvider>(context, listen: false);
  //   if (!connectivityProvider.hasInternet && !_isNetworkAlertShowing) {
  //     _isNetworkAlertShowing = true;
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => AlertDialog(
  //         title: const Text('No Internet Connection'),
  //         content: const Text('Please check your network settings.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               // The dialog will be dismissed automatically when the connection is back.
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } else if (connectivityProvider.hasInternet && _isNetworkAlertShowing) {
  //     Navigator.of(context, rootNavigator: true).pop();
  //     _isNetworkAlertShowing = false;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
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
      body: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildFilterChips(loc),
                // const SizedBox(height: 24),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .snapshots(),
                  builder: (context, cSnap) {
                    return StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('vendors')
                          .snapshots(),
                      builder: (context, vSnap) {
                        return StreamBuilder(
                          stream: _getFilteredQuery().snapshots(),
                          builder: (context, tSnap) {
                            double youWillGet = 0;
                            double youWillPay = 0;

                            // Calculate balances for customers
                            if (cSnap.hasData) {
                              for (var doc in cSnap.data!.docs) {
                                final d = doc.data();
                                double balance =
                                    (d['currentBill'] ?? 0).toDouble() -
                                    (d['paidNow'] ?? 0).toDouble();
                                if (balance > 0) {
                                  youWillGet += balance;
                                } else {
                                  youWillPay += balance.abs();
                                }
                              }
                            }

                            // Calculate balances for vendors
                            if (vSnap.hasData) {
                              for (var doc in vSnap.data!.docs) {
                                final d = doc.data();
                                double balance =
                                    (d['currentBill'] ?? 0).toDouble() -
                                    (d['paidNow'] ?? 0).toDouble();
                                if (balance > 0) {
                                  youWillPay += balance;
                                } else {
                                  youWillGet += balance.abs();
                                }
                              }
                            }

                            // Calculate Net Change from filtered transactions
                            if (tSnap.hasData) {
                              double netChange = 0;
                              for (var doc in tSnap.data!.docs) {
                                final d = doc.data() as Map<String, dynamic>?;
                                if (d != null) {
                                  double paidAmount = (d['paidNow'] ?? 0)
                                      .toDouble();

                                  if (d['entityType'] == 'Customer') {
                                    // Money received from customers (positive)
                                    netChange += paidAmount;
                                  } else if (d['entityType'] == 'Vendor') {
                                    // Money paid to vendors (negative)
                                    netChange -= paidAmount;
                                  }
                                }
                              }
                            }

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: _buildCard(
                                        lang.isMalayalam
                                            ? 'നിങ്ങൾക്ക് കിട്ടാനുള്ളത്'
                                            : 'You will get',
                                        '﷼${youWillGet.toStringAsFixed(2)}',
                                        Icons.arrow_downward,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildCard(
                                        lang.isMalayalam
                                            ? 'നിങ്ങൾക്ക് കൊടുക്കാനുള്ളത്'
                                            : 'You will pay',
                                        '﷼${youWillPay.toStringAsFixed(2)}',
                                        Icons.arrow_upward,
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                // const SizedBox(height: 32),
                // Text(loc.features, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _featureCard(
                      loc.customers,
                      Icons.people,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerListPage(),
                        ),
                      ),
                    ),
                    _featureCard(
                      loc.vendors,
                      Icons.store,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VendorListPage(),
                        ),
                      ),
                    ),
                    _featureCard(
                      loc.products,
                      Icons.inventory_2,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListPage(),
                        ),
                      ),
                    ),
                    _featureCard(
                      loc.reports,
                      Icons.bar_chart,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations loc) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: ['all', 'today', 'week', 'month', 'custom'].map((v) {
            String label = {
              'all': loc.all,
              'today': loc.today,
              'week': loc.thisWeek,
              'month': loc.thisMonth,
              'custom': loc.custom,
            }[v]!;
            return FilterChip(
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: _filterType == v ? Colors.white : Colors.black87,
              ),
              label: Text(label),
              selected: _filterType == v,
              onSelected: (_) {
                setState(() {
                  _filterType = v;
                  if (v != 'custom') _startDate = _endDate = null;
                });
              },
            );
          }).toList(),
        ),
        if (_filterType == 'custom') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  loc.startDate,
                  _startDate,
                  (d) => setState(() => _startDate = d),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateButton(
                  loc.endDate,
                  _endDate,
                  (d) => setState(() => _endDate = d),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _dateButton(String hint, DateTime? date, Function(DateTime) onPicked) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today),
      label: Text(
        date != null ? DateFormat('dd/MM/yy').format(date) : hint,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _buildBigCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    var provider = Provider.of<LanguageProvider>(context, listen: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: provider.isMalayalam ? 12 : 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
