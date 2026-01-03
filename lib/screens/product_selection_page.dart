import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

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

  int get _totalSelectedProducts {
    if (_tempSelected.isEmpty) {
      return 0;
    }
    return _tempSelected.map((p) => p['qty'] as int).reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Products',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
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

                // Sort alphabetically so similar items appear together
                // Sort: Available first, Out of Stock last, then Alphabetical
                products.sort((a, b) {
                  final dataA = a.data();
                  final dataB = b.data();

                  final stockA = (dataA['qty'] ?? 0);
                  final stockB = (dataB['qty'] ?? 0);

                  // If not purchase → available first
                  if (!widget.isPurchase) {
                    // A available, B out of stock → A first
                    if (stockA > 0 && stockB <= 0) return -1;

                    // A out of stock, B available → B first
                    if (stockA <= 0 && stockB > 0) return 1;
                  }

                  // Otherwise fallback to alphabetical sort
                  final nameA = dataA['name'].toString().toLowerCase();
                  final nameB = dataB['name'].toString().toLowerCase();
                  return nameA.compareTo(nameB);
                });

                return GridView.builder(
                  key: const PageStorageKey('product-grid'),
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                    crossAxisCount: 2,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index].data();
                    final selectedProduct = _tempSelected.firstWhere(
                      (p) => p['name'] == product['name'],
                      orElse: () => {},
                    );
                    final isSelected = selectedProduct.isNotEmpty;
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
                                if (!isSelected) {
                                  _tempSelected.add({
                                    'name': product['name'],
                                    'rate': price,
                                    'qty': 1,
                                    'stock': (product['qty'] ?? 0).toDouble(),
                                  });
                                }
                              });
                            },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: Colors.teal,
                                      size: 80,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Text(
                                      //   'Sku: ${product['sku'] ?? 'N/A'}',
                                      //   style: const TextStyle(
                                      //       fontSize: 12,
                                      //       color: Colors.grey),
                                      // ),
                                      Text(
                                        'SRP: ﷼${price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal[700],
                                        ),
                                      ),
                                      if (!widget.isPurchase)
                                        Text(
                                          'Stock: ${product['qty'] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOutOfStock
                                                ? Colors.redAccent
                                                : Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.teal.withOpacity(0.5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${selectedProduct['qty']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (selectedProduct['qty'] > 1) {
                                                selectedProduct['qty']--;
                                              } else {
                                                _tempSelected.removeWhere(
                                                  (p) =>
                                                      p['name'] ==
                                                      product['name'],
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (!widget.isPurchase &&
                                                  selectedProduct['qty'] <
                                                      (product['qty'] ?? 0)) {
                                                selectedProduct['qty']++;
                                              } else if (widget.isPurchase) {
                                                selectedProduct['qty']++;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _tempSelected.removeWhere(
                                        (p) => p['name'] == product['name'],
                                      );
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            if (isOutOfStock)
                              Container(
                                color: Colors.white.withOpacity(0.7),
                                child: const Center(
                                  child: Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
        onPressed: () => Navigator.pop(context, _tempSelected),
        icon: const Icon(Icons.check),
        label: Text('Done ($_totalSelectedProducts)'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
