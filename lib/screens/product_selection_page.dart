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
    _tempSelected = List.from(widget.selectedProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No products available',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final products = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['name'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }).toList();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product =
                          products[index].data() as Map<String, dynamic>;
                      final isSelected = _tempSelected.any(
                        (p) => p['name'] == product['name'],
                      );
                      final selectedProduct = isSelected
                          ? _tempSelected.firstWhere(
                              (p) => p['name'] == product['name'],
                            )
                          : null;
                      final isOutOfStock =
                          !widget.isPurchase && (product['qty'] ?? 0) == 0;
                      final price = widget.isPurchase
                          ? product['price']
                          : product['retailPrice'];
                      return Card(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
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
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '﷼${price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (!widget.isPurchase)
                                    Text(
                                      'Stock: ${product['qty']}',
                                      style: TextStyle(
                                        color: isOutOfStock
                                            ? Colors.redAccent
                                            : Colors.white70,
                                      ),
                                    ),
                                  if (!isOutOfStock)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (isSelected &&
                                                selectedProduct!['qty'] > 1) {
                                              setState(() {
                                                selectedProduct['qty']--;
                                              });
                                            } else {
                                              setState(() {
                                                _tempSelected.removeWhere(
                                                  (p) =>
                                                      p['name'] ==
                                                      product['name'],
                                                );
                                              });
                                            }
                                          },
                                        ),
                                        Text(
                                          isSelected
                                              ? selectedProduct!['qty']
                                                    .toString()
                                              : '0',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (isSelected) {
                                              if (widget.isPurchase ||
                                                  selectedProduct!['qty'] <
                                                      product['qty']) {
                                                setState(() {
                                                  selectedProduct!['qty']++;
                                                });
                                              }
                                            } else {
                                              setState(() {
                                                _tempSelected.add({
                                                  'name': product['name'],
                                                  'rate': price,
                                                  'qty': 1,
                                                });
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (isOutOfStock)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _tempSelected),
        icon: const Icon(Icons.done),
        label: const Text('Done'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
      ),
    );
  }
}
