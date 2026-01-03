import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Products (0)");
            }
            return Text("Products (${snapshot.data!.docs.length})");
          },
        ),
        elevation: 2,
      ),

      body: Column(
        children: [
          // 🔍 Modern Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search products...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 🔄 Product List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("No products available"));
                }

                List docs = snapshot.data!.docs;

                // 🔍 Apply search filter
                List filteredDocs = docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                // 🔄 Sort: available → out of stock → A to Z
                filteredDocs.sort((a, b) {
                  final qtyA = a['qty'] ?? 0;
                  final qtyB = b['qty'] ?? 0;

                  if (qtyA > 0 && qtyB <= 0) return -1;
                  if (qtyA <= 0 && qtyB > 0) return 1;

                  return a['name'].toString().toLowerCase().compareTo(
                    b['name'].toString().toLowerCase(),
                  );
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final product =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;

                    final isOutOfStock = (product['qty'] ?? 0) <= 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: isOutOfStock
                              ? Colors.red.withOpacity(0.15)
                              : Colors.teal.withOpacity(0.15),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: isOutOfStock ? Colors.red : Colors.teal,
                            size: 26,
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Price: ﷼${product['price']}"),
                              Text(
                                "Stock: ${product['qty']} ${product['unit']}",
                              ),
                              if ((product['discount'] ?? 0) > 0)
                                Text("Discount: ${product['discount']}%"),
                              if ((product['tax'] ?? 0) > 0)
                                Text("Tax: ${product['tax']}%"),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddProductPage(
                                docId: docId,
                                existingData: product,
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
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }
}
