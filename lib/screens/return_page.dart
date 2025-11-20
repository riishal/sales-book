import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnPage extends StatefulWidget {
  final String entityId;

  const ReturnPage({super.key, required this.entityId});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _returnedProducts = [];
  double _totalReturnValue = 0;
  List<Map<String, dynamic>> _purchasedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchPurchasedProducts();
  }

  Future<void> _fetchPurchasedProducts() async {
    setState(() => _isLoading = true);
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('entityId', isEqualTo: widget.entityId)
        .where('type', isEqualTo: 'Sale')
        .get();

    final Map<String, Map<String, dynamic>> productMap = {};
    for (var doc in transactionsSnapshot.docs) {
      final transaction = doc.data();
      for (var product in transaction['products']) {
        if (productMap.containsKey(product['name'])) {
          productMap[product['name']]!['qty'] += product['qty'];
        } else {
          productMap[product['name']] = {
            'name': product['name'],
            'rate': product['rate'],
            'qty': product['qty'],
          };
        }
      }
    }
    if (mounted) {
      setState(() {
        _purchasedProducts = productMap.values.toList();
        _isLoading = false;
      });
    }
  }

  void _calculateTotal() {
    _totalReturnValue = 0;
    for (var product in _returnedProducts) {
      _totalReturnValue +=
          (product['rate'] as double) * (product['qty'] as num);
    }
    setState(() {});
  }

  Future<void> _saveReturn() async {
    if (_returnedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product to return.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.entityId)
          .get();
      final customerName = customerDoc.data()?['name'] ?? '';

      // Create a transaction record for the return
      await FirebaseFirestore.instance.collection('transactions').add({
        'entityId': widget.entityId,
        'entityName': customerName,
        'entityType': 'Customer',
        'type': 'Return',
        'amount': _totalReturnValue,
        'products': _returnedProducts,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the customer's balance
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.entityId);
      await customerRef.update({
        'currentBill': FieldValue.increment(-_totalReturnValue),
      });

      // Update the stock for each returned product
      for (var product in _returnedProducts) {
        final productQuery = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isEqualTo: product['name'])
            .get();
        if (productQuery.docs.isNotEmpty) {
          final productDoc = productQuery.docs.first;
          await productDoc.reference.update({
            'qty': FieldValue.increment((product['qty'] as num).toDouble()),
          });
        }
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Return',
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
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPurchasedProductsList(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total Return Value: ﷼${_totalReturnValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Return',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedProductsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    if (_purchasedProducts.isEmpty) {
      return const Center(
        child: Text(
          'No purchased products found for this customer.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _purchasedProducts.length,
      itemBuilder: (context, index) {
        final product = _purchasedProducts[index];
        final selectedProduct = _returnedProducts.firstWhere(
          (p) => p['name'] == product['name'],
          orElse: () => {'qty': 0},
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          child: ListTile(
            title: Text(
              product['name'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Purchased Qty: ${product['qty']}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      if (selectedProduct['qty'] > 0) {
                        if (selectedProduct['qty'] == 1) {
                          _returnedProducts.removeWhere(
                            (p) => p['name'] == product['name'],
                          );
                        } else {
                          selectedProduct['qty']--;
                        }
                        _calculateTotal();
                      }
                    });
                  },
                ),
                Text(
                  selectedProduct['qty'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      if (selectedProduct['qty'] < product['qty']) {
                        if (selectedProduct['qty'] == 0) {
                          _returnedProducts.add({
                            'name': product['name'],
                            'rate': product['rate'],
                            'qty': 1,
                          });
                        } else {
                          selectedProduct['qty']++;
                        }
                        _calculateTotal();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
