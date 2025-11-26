// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AddInvestorPage extends StatefulWidget {
//   final String? docId;
//   final Map<String, dynamic>? existingData;

//   const AddInvestorPage({super.key, this.docId, this.existingData});

//   @override
//   State<AddInvestorPage> createState() => _AddInvestorPageState();
// }

// class _AddInvestorPageState extends State<AddInvestorPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _amountController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.existingData != null) {
//       _nameController.text = widget.existingData!['name'] ?? '';
//       _amountController.text = (widget.existingData!['amount'] ?? 0).toString();
//     }
//   }

//   Future<void> _saveInvestor() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);

//     final data = {
//       'name': _nameController.text,
//       'amount': double.parse(_amountController.text),
//       'timestamp': FieldValue.serverTimestamp(),
//     };
//     try {
//       if (widget.docId != null) {
//         await FirebaseFirestore.instance
//             .collection('investors')
//             .doc(widget.docId)
//             .update(data);
//       } else {
//         await FirebaseFirestore.instance.collection('investors').add(data);
//       }
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.docId != null ? 'Edit Investor' : 'Add Investor',
//         ),
//       ),
//       body: Stack(
//         children: [
//           Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Investor Name',
//                     prefixIcon: Icon(Icons.person),
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _amountController,
//                   decoration: const InputDecoration(
//                     labelText: 'Amount',
//                     prefixIcon: Icon(Icons.attach_money),
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: _saveInvestor,
//                   child: const Text(
//                     'Save Investor',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (_isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
