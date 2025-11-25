import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Products (0)'),
              ),
              body: const Center(
                child: Text(
                  'No products yet',
                ),
              ),
              floatingActionButton: _buildFloatingActionButton(context),
            );
          }

          final products = snapshot.data!.docs;
          return Scaffold(
            appBar: AppBar(
              title: Text('Products (${products.length})'),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index].data() as Map<String, dynamic>;
                final docId = products[index].id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price: ﷼${product['price']}',
                        ),
                        Text(
                          'Qty: ${product['qty']} ${product['unit']}',
                        ),
                        if ((product['discount'] ?? 0) > 0)
                          Text(
                            'Discount: ${product['discount']}%',
                          ),
                        if ((product['tax'] ?? 0) > 0)
                          Text(
                            'Tax: ${product['tax']}%',
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(docId)
                            .delete();
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddProductPage(docId: docId, existingData: product),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            floatingActionButton: _buildFloatingActionButton(context),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductPage()),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
    );
  }
}
