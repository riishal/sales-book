import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/provider/language_provider.dart';
import 'add_customer_page.dart';
import 'customer_details_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Customers'),
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
          body: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    hintText: lang.isMalayalam
                        ? 'പേര് അല്ലെങ്കിൽ ഫോൺ തിരയുക'
                        : 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase().trim();
                    });
                  },
                ),
              ),
              // Customer List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          lang.isMalayalam
                              ? 'ഇതുവരെ ഉപഭോക്താക്കൾ ഇല്ല'
                              : 'No customers yet',
                        ),
                      );
                    }

                    var customers = snapshot.data!.docs;

                    // Filter customers based on search query
                    if (_searchQuery.isNotEmpty) {
                      customers = customers.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final phone = (data['phone'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(_searchQuery) ||
                            phone.contains(_searchQuery);
                      }).toList();
                    }

                    if (customers.isEmpty) {
                      return Center(
                        child: Text(
                          lang.isMalayalam
                              ? 'ഒരു ഉപഭോക്താവും കണ്ടെത്തിയില്ല'
                              : 'No customers found',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer =
                            customers[index].data() as Map<String, dynamic>;
                        final docId = customers[index].id;
                        final balance =
                            (customer['currentBill'] ?? 0.0) -
                            (customer['paidNow'] ?? 0.0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              child: Text(
                                (customer['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              customer['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer['phone'] ?? ''),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final String balanceText;
                                    final Color balanceColor;
                                    if (balance > 0) {
                                      balanceText = lang.isMalayalam
                                          ? 'നിങ്ങൾക്ക് കിട്ടാനുള്ളത്: ﷼${balance.toStringAsFixed(2)}'
                                          : 'You will get: ﷼${balance.toStringAsFixed(2)}';
                                      balanceColor = Colors.green;
                                    } else if (balance < 0) {
                                      balanceText = lang.isMalayalam
                                          ? 'നിങ്ങൾക്ക് കൊടുക്കാനുള്ളത്: ﷼${(-balance).toStringAsFixed(2)}'
                                          : 'You will pay: ﷼${(-balance).toStringAsFixed(2)}';
                                      balanceColor = Colors.red;
                                    } else {
                                      balanceText = lang.isMalayalam
                                          ? 'കിട്ടാനോ കൊടുക്കാനോ ഇല്ല'
                                          : 'Settled';
                                      balanceColor = Colors.teal;
                                    }
                                    return Text(
                                      balanceText,
                                      style: TextStyle(
                                        fontSize: lang.isMalayalam ? 12 : 14,
                                        color: balanceColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailsPage(
                                    docId: docId,
                                    customerData: customer,
                                  ),
                                ),
                              );
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
      },
    );
  }
}
