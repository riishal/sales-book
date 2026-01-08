import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/provider/language_provider.dart';
import 'add_vendor_page.dart';
import 'vendor_details_page.dart';

class VendorListPage extends StatefulWidget {
  const VendorListPage({super.key});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage> {
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
            title: const Text('Vendors'),
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
              // Search Field with Clear Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: lang.isMalayalam
                        ? 'പേര് അല്ലെങ്കിൽ ഫോൺ തിരയുക'
                        : 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
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

              // Vendor List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vendors')
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
                              ? 'ഇതുവരെ വെണ്ടേഴ്സ് ഇല്ല'
                              : 'No vendors yet',
                        ),
                      );
                    }

                    var vendors = snapshot.data!.docs;

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      vendors = vendors.where((doc) {
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

                    if (vendors.isEmpty) {
                      return Center(
                        child: Text(
                          lang.isMalayalam
                              ? 'ഒരു വെണ്ടറും കണ്ടെത്തിയില്ല'
                              : 'No vendors found',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: vendors.length,
                      itemBuilder: (context, index) {
                        final vendor =
                            vendors[index].data() as Map<String, dynamic>;
                        final docId = vendors[index].id;
                        final balance =
                            (vendor['currentBill'] ?? 0.0) -
                            (vendor['paidNow'] ?? 0.0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              child: Text(
                                (vendor['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              vendor['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vendor['phone'] ?? ''),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final String balanceText;
                                    final Color balanceColor;

                                    if (balance > 0) {
                                      balanceText = lang.isMalayalam
                                          ? 'നിങ്ങൾക്ക് കൊടുക്കാനുള്ളത്: ﷼${balance.toStringAsFixed(2)}'
                                          : 'You will pay: ﷼${balance.toStringAsFixed(2)}';
                                      balanceColor = Colors.red;
                                    } else if (balance < 0) {
                                      balanceText = lang.isMalayalam
                                          ? 'നിങ്ങൾക്ക് കിട്ടാനുള്ളത്: ﷼${(-balance).toStringAsFixed(2)}'
                                          : 'You will get: ﷼${(-balance).toStringAsFixed(2)}';
                                      balanceColor = Colors.green;
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
                                  builder: (_) => VendorDetailsPage(
                                    docId: docId,
                                    vendorData: vendor,
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
                MaterialPageRoute(builder: (_) => const AddVendorPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Vendor'),
          ),
        );
      },
    );
  }
}
