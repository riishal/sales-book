import 'package:flutter/material.dart';

class SelectedProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onRemove;
  final bool isPurchase;

  const SelectedProductCard({
    super.key,
    required this.product,
    required this.onUpdate,
    required this.onRemove,
    this.isPurchase = false,
  });

  @override
  State<SelectedProductCard> createState() => _SelectedProductCardState();
}

class _SelectedProductCardState extends State<SelectedProductCard> {
  late TextEditingController _rateController;
  late TextEditingController _qtyController;
  final FocusNode _qtyFocusNode = FocusNode();
  final FocusNode _rateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.product['rate'].toString(),
    );
    _qtyController = TextEditingController(
      text: widget.product['qty'].toString(),
    );

    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) {
        _updateQuantity();
      }
    });

    _rateFocusNode.addListener(() {
      if (!_rateFocusNode.hasFocus) {
        _updateRate();
      }
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    _rateFocusNode.dispose();
    super.dispose();
  }

  void _updateRate() {
    final newRate =
        double.tryParse(_rateController.text) ?? widget.product['rate'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUpdate({'rate': newRate});
    });
  }

  void _updateQuantity() {
    int newQty =
        int.tryParse(_qtyController.text) ??
        (widget.product['qty'] as num).toInt();
    if (!widget.isPurchase) {
      final stock = (widget.product['stock'] as num?)?.toInt() ?? 0;
      if (newQty > stock) {
        newQty = stock;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot exceed available stock of $stock')),
        );
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUpdate({'qty': newQty});
    });
  }

  @override
  void didUpdateWidget(SelectedProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product['qty'] != num.tryParse(_qtyController.text)) {
      _qtyController.text = widget.product['qty'].toString();
    }
    if (widget.product['rate'] != double.tryParse(_rateController.text)) {
      _rateController.text = widget.product['rate'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    double total =
        (widget.product['rate'] as double) * (widget.product['qty'] as num);
    final stock = (widget.product['stock'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.teal.withOpacity(0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.product['name'],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.teal),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            if (!widget.isPurchase) ...[
              const SizedBox(height: 4),
              Text(
                'Available Stock: $stock',
                style: const TextStyle(color: Colors.teal, fontSize: 12),
              ),
            ],
            const SizedBox(height: 17),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Rate',
                    _rateController,
                    null,
                    focusNode: _rateFocusNode,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    'Qty',
                    _qtyController,
                    null,
                    focusNode: _qtyFocusNode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: riyal ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String)? onChanged, {
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: Colors.black87.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
