import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;
  final bool isPurchase;

  const ProductSelectionPage({
    super.key,
    required this.selectedProducts,
    this.isPurchase = false,
  });

  @override
  State<ProductSelectionPage> createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Map<String, dynamic>> _tempSelected = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(
      widget.selectedProducts.map((p) => Map<String, dynamic>.from(p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Products (${_tempSelected.length})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [
          //     Theme.of(context).primaryColor,
          //     Theme.of(context).primaryColorLight,
          //   ],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Products...',
                  hintStyle: const TextStyle(color: Colors.black87),
                  prefixIcon: const Icon(Icons.search, color: Colors.black87),
                  filled: true,
                  fillColor: Colors.black87.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
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
                        'No products available',
                        style: TextStyle(color: Colors.black87),
                      ),
                    );
                  }
                  final products = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    return data['name'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }).toList();

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            // mainAxisExtent: 200,
                            childAspectRatio: 0.8,
                            crossAxisCount: 2,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index].data();
                        final isSelected = _tempSelected.any(
                          (p) => p['name'] == product['name'],
                        );
                        final isOutOfStock =
                            !widget.isPurchase && (product['qty'] ?? 0) <= 0;
                        final price = widget.isPurchase
                            ? (product['price'] ?? 0.0)
                            : (product['retailPrice'] ?? 0.0);

                        return GestureDetector(
                          onTap: isOutOfStock
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _tempSelected.removeWhere(
                                        (p) => p['name'] == product['name'],
                                      );
                                    } else {
                                      _tempSelected.add({
                                        'name': product['name'],
                                        'rate': price,
                                        'qty': 1, // Default quantity is 1
                                        'stock': (product['qty'] ?? 0)
                                            .toDouble(),
                                      });
                                    }
                                  });
                                },
                          child: Card(
                            color: isSelected
                                ? Colors.teal.withOpacity(0.2)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.teal.withOpacity(0.1),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.inventory_2,
                                        color: Colors.teal,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        '﷼${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (!widget.isPurchase)
                                        Text(
                                          'Stock: ${product['qty'] ?? 0}',
                                          style: TextStyle(
                                            color: isOutOfStock
                                                ? Colors.redAccent
                                                : Colors.black87,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isOutOfStock)
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          SizedBox(height: 10),
                                          Text(
                                            'Out of Stock',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.teal,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _tempSelected),
        icon: const Icon(Icons.done),
        label: const Text('Done'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
