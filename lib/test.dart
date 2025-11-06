// // pubspec.yaml dependencies needed:
// // dependencies:
// //   flutter:
// //     sdk: flutter
// //   firebase_core: ^2.24.2
// //   cloud_firestore: ^4.13.6
// //   intl: ^0.18.1
// //   pdf: ^3.10.7
// //   printing: ^5.11.1
// //   share_plus: ^7.2.1
// //   url_launcher: ^6.2.2

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const SalesApp());
// }

// class SalesApp extends StatelessWidget {
//   const SalesApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sales Management',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.white,
//         cardTheme: const CardThemeData(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(20)),
//           ),
//           color: Colors.white,
//         ),
//         appBarTheme: const AppBarTheme(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           foregroundColor: Colors.black,
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//           ),
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.blue),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.blue, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//           labelStyle: const TextStyle(color: Colors.black),
//         ),
//         textTheme: const TextTheme(
//           bodyLarge: TextStyle(color: Colors.black),
//           bodyMedium: TextStyle(color: Colors.black),
//           titleLarge: TextStyle(color: Colors.black),
//         ),
//         iconTheme: const IconThemeData(color: Colors.blue),
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Sales Dashboard',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('customers')
//                   .snapshots(),
//               builder: (context, customerSnapshot) {
//                 return StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('vendors')
//                       .snapshots(),
//                   builder: (context, vendorSnapshot) {
//                     double totalReceived = 0;
//                     double totalPaid = 0;
//                     if (customerSnapshot.hasData) {
//                       for (var doc in customerSnapshot.data!.docs) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         totalReceived += (data['paidNow'] ?? 0.0).toDouble();
//                       }
//                     }
//                     if (vendorSnapshot.hasData) {
//                       for (var doc in vendorSnapshot.data!.docs) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         totalPaid += (data['paidNow'] ?? 0.0).toDouble();
//                       }
//                     }
//                     double netReceived = totalReceived - totalPaid;
//                     return Column(
//                       children: [
//                         _buildStatCard(
//                           'Total Received',
//                           '﷼${totalReceived.toStringAsFixed(2)}',
//                           Icons.arrow_downward,
//                         ),
//                         const SizedBox(height: 12),
//                         _buildStatCard(
//                           'Net Received',
//                           '﷼${netReceived.toStringAsFixed(2)}',
//                           Icons.account_balance_wallet,
//                         ),
//                         const SizedBox(height: 12),
//                         _buildStatCard(
//                           'Total Paid',
//                           '﷼${totalPaid.toStringAsFixed(2)}',
//                           Icons.arrow_upward,
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'Features',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 16),
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 _buildFeatureCard(
//                   context,
//                   'Customers',
//                   Icons.people,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const CustomerListPage()),
//                   ),
//                 ),
//                 _buildFeatureCard(
//                   context,
//                   'Vendors',
//                   Icons.store,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const VendorListPage()),
//                   ),
//                 ),
//                 _buildFeatureCard(
//                   context,
//                   'Products',
//                   Icons.inventory_2,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const ProductListPage()),
//                   ),
//                 ),
//                 _buildFeatureCard(
//                   context,
//                   'Reports',
//                   Icons.analytics,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const ReportsPage()),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.blue),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.1),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: Colors.blue, size: 28),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(color: Colors.black54, fontSize: 14),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeatureCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.blue.withOpacity(0.5)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, size: 40, color: Colors.blue),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CustomerListPage extends StatelessWidget {
//   const CustomerListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Customers', style: TextStyle(color: Colors.black)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('customers')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No customers yet',
//                 style: TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           final customers = snapshot.data!.docs;
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: customers.length,
//             itemBuilder: (context, index) {
//               final customer = customers[index].data() as Map<String, dynamic>;
//               final docId = customers[index].id;
//               final balance =
//                   (customer['currentBill'] ?? 0.0) -
//                   (customer['paidNow'] ?? 0.0);
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16),
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.blue.withOpacity(0.1),
//                     child: Text(
//                       customer['name'][0].toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     customer['name'],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         customer['phone'],
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         balance <= 0
//                             ? 'Settled'
//                             : 'You will get: ﷼${balance.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.blue),
//                     onPressed: () async {
//                       await FirebaseFirestore.instance
//                           .collection('customers')
//                           .doc(docId)
//                           .delete();
//                     },
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => AddCustomerPage(
//                           docId: docId,
//                           existingData: customer,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const AddCustomerPage()),
//           );
//         },
//         icon: const Icon(Icons.add),
//         label: const Text('Add Customer'),
//       ),
//     );
//   }
// }

// class AddCustomerPage extends StatefulWidget {
//   final String? docId;
//   final Map<String, dynamic>? existingData;

//   const AddCustomerPage({super.key, this.docId, this.existingData});

//   @override
//   State<AddCustomerPage> createState() => _AddCustomerPageState();
// }

// class _AddCustomerPageState extends State<AddCustomerPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _previousBalanceController = TextEditingController(text: '0');
//   final _additionalChargeController = TextEditingController(text: '0');
//   final _discountController = TextEditingController(text: '0');
//   final _taxController = TextEditingController(text: '0');
//   final _paidNowController = TextEditingController(text: '0');
//   List<Map<String, dynamic>> selectedProducts = [];
//   double currentBill = 0;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.existingData != null) {
//       _nameController.text = widget.existingData!['name'] ?? '';
//       _phoneController.text = widget.existingData!['phone'] ?? '';
//       _previousBalanceController.text =
//           (widget.existingData!['previousBalance'] ?? 0).toString();
//       _additionalChargeController.text =
//           (widget.existingData!['additionalCharge'] ?? 0).toString();
//       _discountController.text = (widget.existingData!['discount'] ?? 0)
//           .toString();
//       _taxController.text = (widget.existingData!['tax'] ?? 0).toString();
//       _paidNowController.text = (widget.existingData!['paidNow'] ?? 0)
//           .toString();
//       selectedProducts = List<Map<String, dynamic>>.from(
//         widget.existingData!['products'] ?? [],
//       );
//       _calculateTotal();
//     }
//   }

//   void _calculateTotal() {
//     double subtotal = 0;
//     for (var product in selectedProducts) {
//       subtotal += (product['rate'] as double) * (product['qty'] as double);
//     }
//     double additional = double.tryParse(_additionalChargeController.text) ?? 0;
//     double discount = double.tryParse(_discountController.text) ?? 0;
//     double tax = double.tryParse(_taxController.text) ?? 0;
//     double previous = double.tryParse(_previousBalanceController.text) ?? 0;
//     currentBill =
//         subtotal + additional - discount + (subtotal * tax / 100) + previous;
//     setState(() {});
//   }

//   Future<void> _selectProducts() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             ProductSelectionPage(selectedProducts: selectedProducts),
//       ),
//     );
//     if (result != null) {
//       setState(() {
//         selectedProducts = result as List<Map<String, dynamic>>;
//         _calculateTotal();
//       });
//     }
//   }

//   Future<void> _saveCustomer() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//     final data = {
//       'name': _nameController.text,
//       'phone': _phoneController.text,
//       'previousBalance': double.parse(_previousBalanceController.text),
//       'currentBill': currentBill,
//       'additionalCharge': double.parse(_additionalChargeController.text),
//       'discount': double.parse(_discountController.text),
//       'tax': double.parse(_taxController.text),
//       'paidNow': double.parse(_paidNowController.text),
//       'products': selectedProducts,
//       'timestamp': FieldValue.serverTimestamp(),
//     };
//     try {
//       if (widget.docId != null) {
//         await FirebaseFirestore.instance
//             .collection('customers')
//             .doc(widget.docId)
//             .update(data);
//         Navigator.pop(context);
//       } else {
//         final docRef = await FirebaseFirestore.instance
//             .collection('customers')
//             .add(data);
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) =>
//                 InvoicePage(docId: docRef.id, data: data, type: 'customer'),
//           ),
//         );
//       }
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
//           widget.docId != null ? 'Edit Customer' : 'Add Customer',
//           style: const TextStyle(color: Colors.black),
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
//                   decoration: const InputDecoration(labelText: 'Name'),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _phoneController,
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   keyboardType: TextInputType.phone,
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _previousBalanceController,
//                   decoration: const InputDecoration(
//                     labelText: 'Previous Balance',
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton.icon(
//                   onPressed: _selectProducts,
//                   icon: const Icon(Icons.add_shopping_cart),
//                   label: const Text('Select Products'),
//                 ),
//                 const SizedBox(height: 16),
//                 if (selectedProducts.isNotEmpty)
//                   ...selectedProducts.asMap().entries.map((entry) {
//                     final idx = entry.key;
//                     final product = entry.value;
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       child: ListTile(
//                         title: Text(
//                           product['name'],
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                         subtitle: Row(
//                           children: [
//                             SizedBox(
//                               width: 80,
//                               child: TextFormField(
//                                 initialValue: product['qty'].toString(),
//                                 decoration: const InputDecoration(
//                                   labelText: 'Qty',
//                                 ),
//                                 keyboardType: TextInputType.number,
//                                 onChanged: (v) {
//                                   selectedProducts[idx]['qty'] =
//                                       double.tryParse(v) ?? 1;
//                                   _calculateTotal();
//                                 },
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Text(
//                               'Rate: ﷼${product['rate']}',
//                               style: const TextStyle(color: Colors.black),
//                             ),
//                           ],
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               selectedProducts.removeAt(idx);
//                             });
//                             _calculateTotal();
//                           },
//                         ),
//                       ),
//                     );
//                   }),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _additionalChargeController,
//                   decoration: const InputDecoration(
//                     labelText: 'Additional Charge',
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _discountController,
//                   decoration: const InputDecoration(labelText: 'Discount'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _taxController,
//                   decoration: const InputDecoration(labelText: 'Tax (%)'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     'Current Bill: ﷼${currentBill.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _paidNowController,
//                   decoration: const InputDecoration(labelText: 'Paid Now'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: _saveCustomer,
//                   child: const Text('Save', style: TextStyle(fontSize: 18)),
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

// class VendorListPage extends StatelessWidget {
//   const VendorListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Vendors', style: TextStyle(color: Colors.black)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('vendors')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No vendors yet',
//                 style: TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           final vendors = snapshot.data!.docs;
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: vendors.length,
//             itemBuilder: (context, index) {
//               final vendor = vendors[index].data() as Map<String, dynamic>;
//               final docId = vendors[index].id;
//               final balance =
//                   (vendor['currentBill'] ?? 0.0) - (vendor['paidNow'] ?? 0.0);
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16),
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.blue.withOpacity(0.1),
//                     child: Text(
//                       vendor['name'][0].toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     vendor['name'],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         vendor['phone'],
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         balance <= 0
//                             ? 'Settled'
//                             : 'You will pay: ﷼${balance.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.blue),
//                     onPressed: () async {
//                       await FirebaseFirestore.instance
//                           .collection('vendors')
//                           .doc(docId)
//                           .delete();
//                     },
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             AddVendorPage(docId: docId, existingData: vendor),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const AddVendorPage()),
//           );
//         },
//         icon: const Icon(Icons.add),
//         label: const Text('Add Vendor'),
//       ),
//     );
//   }
// }

// class AddVendorPage extends StatefulWidget {
//   final String? docId;
//   final Map<String, dynamic>? existingData;

//   const AddVendorPage({super.key, this.docId, this.existingData});

//   @override
//   State<AddVendorPage> createState() => _AddVendorPageState();
// }

// class _AddVendorPageState extends State<AddVendorPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _previousBalanceController = TextEditingController(text: '0');
//   final _additionalChargeController = TextEditingController(text: '0');
//   final _discountController = TextEditingController(text: '0');
//   final _taxController = TextEditingController(text: '0');
//   final _paidNowController = TextEditingController(text: '0');
//   List<Map<String, dynamic>> selectedProducts = [];
//   double currentBill = 0;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.existingData != null) {
//       _nameController.text = widget.existingData!['name'] ?? '';
//       _phoneController.text = widget.existingData!['phone'] ?? '';
//       _previousBalanceController.text =
//           (widget.existingData!['previousBalance'] ?? 0).toString();
//       _additionalChargeController.text =
//           (widget.existingData!['additionalCharge'] ?? 0).toString();
//       _discountController.text = (widget.existingData!['discount'] ?? 0)
//           .toString();
//       _taxController.text = (widget.existingData!['tax'] ?? 0).toString();
//       _paidNowController.text = (widget.existingData!['paidNow'] ?? 0)
//           .toString();
//       selectedProducts = List<Map<String, dynamic>>.from(
//         widget.existingData!['products'] ?? [],
//       );
//       _calculateTotal();
//     }
//   }

//   void _calculateTotal() {
//     double subtotal = 0;
//     for (var product in selectedProducts) {
//       subtotal += (product['rate'] as double) * (product['qty'] as double);
//     }
//     double additional = double.tryParse(_additionalChargeController.text) ?? 0;
//     double discount = double.tryParse(_discountController.text) ?? 0;
//     double tax = double.tryParse(_taxController.text) ?? 0;
//     double previous = double.tryParse(_previousBalanceController.text) ?? 0;
//     currentBill =
//         subtotal + additional - discount + (subtotal * tax / 100) + previous;
//     setState(() {});
//   }

//   Future<void> _selectProducts() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             ProductSelectionPage(selectedProducts: selectedProducts),
//       ),
//     );
//     if (result != null) {
//       setState(() {
//         selectedProducts = result as List<Map<String, dynamic>>;
//         _calculateTotal();
//       });
//     }
//   }

//   Future<void> _saveVendor() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//     final data = {
//       'name': _nameController.text,
//       'phone': _phoneController.text,
//       'previousBalance': double.parse(_previousBalanceController.text),
//       'currentBill': currentBill,
//       'additionalCharge': double.parse(_additionalChargeController.text),
//       'discount': double.parse(_discountController.text),
//       'tax': double.parse(_taxController.text),
//       'paidNow': double.parse(_paidNowController.text),
//       'products': selectedProducts,
//       'timestamp': FieldValue.serverTimestamp(),
//     };
//     try {
//       if (widget.docId != null) {
//         await FirebaseFirestore.instance
//             .collection('vendors')
//             .doc(widget.docId)
//             .update(data);
//         Navigator.pop(context);
//       } else {
//         final docRef = await FirebaseFirestore.instance
//             .collection('vendors')
//             .add(data);
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) =>
//                 InvoicePage(docId: docRef.id, data: data, type: 'vendor'),
//           ),
//         );
//       }
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
//           widget.docId != null ? 'Edit Vendor' : 'Add Vendor',
//           style: const TextStyle(color: Colors.black),
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
//                   decoration: const InputDecoration(labelText: 'Name'),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _phoneController,
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   keyboardType: TextInputType.phone,
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _previousBalanceController,
//                   decoration: const InputDecoration(
//                     labelText: 'Previous Balance',
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton.icon(
//                   onPressed: _selectProducts,
//                   icon: const Icon(Icons.add_shopping_cart),
//                   label: const Text('Select Products'),
//                 ),
//                 const SizedBox(height: 16),
//                 if (selectedProducts.isNotEmpty)
//                   ...selectedProducts.asMap().entries.map((entry) {
//                     final idx = entry.key;
//                     final product = entry.value;
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       child: ListTile(
//                         title: Text(
//                           product['name'],
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                         subtitle: Row(
//                           children: [
//                             SizedBox(
//                               width: 80,
//                               child: TextFormField(
//                                 initialValue: product['qty'].toString(),
//                                 decoration: const InputDecoration(
//                                   labelText: 'Qty',
//                                 ),
//                                 keyboardType: TextInputType.number,
//                                 onChanged: (v) {
//                                   selectedProducts[idx]['qty'] =
//                                       double.tryParse(v) ?? 1;
//                                   _calculateTotal();
//                                 },
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Text(
//                               'Rate: ﷼${product['rate']}',
//                               style: const TextStyle(color: Colors.black),
//                             ),
//                           ],
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               selectedProducts.removeAt(idx);
//                             });
//                             _calculateTotal();
//                           },
//                         ),
//                       ),
//                     );
//                   }),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _additionalChargeController,
//                   decoration: const InputDecoration(
//                     labelText: 'Additional Charge',
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _discountController,
//                   decoration: const InputDecoration(labelText: 'Discount'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _taxController,
//                   decoration: const InputDecoration(labelText: 'Tax (%)'),
//                   keyboardType: TextInputType.number,
//                   onChanged: (_) => _calculateTotal(),
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     'Current Bill: ﷼${currentBill.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _paidNowController,
//                   decoration: const InputDecoration(labelText: 'Paid Now'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: _saveVendor,
//                   child: const Text('Save', style: TextStyle(fontSize: 18)),
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

// class ProductListPage extends StatelessWidget {
//   const ProductListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Products', style: TextStyle(color: Colors.black)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('products')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No products yet',
//                 style: TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           final products = snapshot.data!.docs;
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index].data() as Map<String, dynamic>;
//               final docId = products[index].id;
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16),
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.blue.withOpacity(0.1),
//                     child: const Icon(Icons.inventory_2, color: Colors.blue),
//                   ),
//                   title: Text(
//                     product['name'],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Price: ﷼${product['price']}',
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                       Text(
//                         'Qty: ${product['qty']} ${product['unit']}',
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                       if (product['discount'] > 0)
//                         Text(
//                           'Discount: ${product['discount']}%',
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                       if (product['tax'] > 0)
//                         Text(
//                           'Tax: ${product['tax']}%',
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                     ],
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.blue),
//                     onPressed: () async {
//                       await FirebaseFirestore.instance
//                           .collection('products')
//                           .doc(docId)
//                           .delete();
//                     },
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             AddProductPage(docId: docId, existingData: product),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const AddProductPage()),
//           );
//         },
//         icon: const Icon(Icons.add),
//         label: const Text('Add Product'),
//       ),
//     );
//   }
// }

// class AddProductPage extends StatefulWidget {
//   final String? docId;
//   final Map<String, dynamic>? existingData;

//   const AddProductPage({super.key, this.docId, this.existingData});

//   @override
//   State<AddProductPage> createState() => _AddProductPageState();
// }

// class _AddProductPageState extends State<AddProductPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _qtyController = TextEditingController(text: '0');
//   final _unitController = TextEditingController(text: 'pcs');
//   final _discountController = TextEditingController(text: '0');
//   final _taxController = TextEditingController(text: '0');
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.existingData != null) {
//       _nameController.text = widget.existingData!['name'] ?? '';
//       _priceController.text = (widget.existingData!['price'] ?? 0).toString();
//       _qtyController.text = (widget.existingData!['qty'] ?? 0).toString();
//       _unitController.text = widget.existingData!['unit'] ?? 'pcs';
//       _discountController.text = (widget.existingData!['discount'] ?? 0)
//           .toString();
//       _taxController.text = (widget.existingData!['tax'] ?? 0).toString();
//     }
//   }

//   Future<void> _saveProduct() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//     final data = {
//       'name': _nameController.text,
//       'price': double.parse(_priceController.text),
//       'qty': double.parse(_qtyController.text),
//       'unit': _unitController.text,
//       'discount': double.parse(_discountController.text),
//       'tax': double.parse(_taxController.text),
//       'total':
//           double.parse(_priceController.text) *
//           double.parse(_qtyController.text),
//       'timestamp': FieldValue.serverTimestamp(),
//     };
//     try {
//       if (widget.docId != null) {
//         await FirebaseFirestore.instance
//             .collection('products')
//             .doc(widget.docId)
//             .update(data);
//       } else {
//         await FirebaseFirestore.instance.collection('products').add(data);
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
//           widget.docId != null ? 'Edit Product' : 'Add Product',
//           style: const TextStyle(color: Colors.black),
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
//                     labelText: 'Product Name',
//                     prefixIcon: Icon(Icons.inventory_2),
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _priceController,
//                   decoration: const InputDecoration(
//                     labelText: 'Price',
//                     prefixIcon: Icon(Icons.attach_money),
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: TextFormField(
//                         controller: _qtyController,
//                         decoration: const InputDecoration(
//                           labelText: 'Quantity',
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: TextFormField(
//                         controller: _unitController,
//                         decoration: const InputDecoration(labelText: 'Unit'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _discountController,
//                   decoration: const InputDecoration(
//                     labelText: 'Discount (%)',
//                     prefixIcon: Icon(Icons.discount),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _taxController,
//                   decoration: const InputDecoration(
//                     labelText: 'Tax (%)',
//                     prefixIcon: Icon(Icons.receipt),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: _saveProduct,
//                   child: const Text(
//                     'Save Product',
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

// class ReportsPage extends StatefulWidget {
//   const ReportsPage({super.key});

//   @override
//   State<ReportsPage> createState() => _ReportsPageState();
// }

// class _ReportsPageState extends State<ReportsPage> {
//   String filterType = 'all';
//   DateTime? startDate;
//   DateTime? endDate;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reports', style: TextStyle(color: Colors.black)),
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Column(
//               children: [
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _buildFilterChip('All', 'all'),
//                     _buildFilterChip('Today', 'today'),
//                     _buildFilterChip('Month', 'month'),
//                     _buildFilterChip('Custom', 'custom'),
//                   ],
//                 ),
//                 if (filterType == 'custom') ...[
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: DateTime.now(),
//                               firstDate: DateTime(2020),
//                               lastDate: DateTime.now(),
//                             );
//                             if (date != null) setState(() => startDate = date);
//                           },
//                           icon: const Icon(Icons.calendar_today),
//                           label: Text(
//                             startDate != null
//                                 ? DateFormat('dd/MM/yy').format(startDate!)
//                                 : 'Start Date',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: DateTime.now(),
//                               firstDate: DateTime(2020),
//                               lastDate: DateTime.now(),
//                             );
//                             if (date != null) setState(() => endDate = date);
//                           },
//                           icon: const Icon(Icons.calendar_today),
//                           label: Text(
//                             endDate != null
//                                 ? DateFormat('dd/MM/yy').format(endDate!)
//                                 : 'End Date',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('customers')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, customerSnapshot) {
//                 return StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('vendors')
//                       .orderBy('timestamp', descending: true)
//                       .snapshots(),
//                   builder: (context, vendorSnapshot) {
//                     if (customerSnapshot.connectionState ==
//                             ConnectionState.waiting ||
//                         vendorSnapshot.connectionState ==
//                             ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (customerSnapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'Error: ${customerSnapshot.error}',
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                       );
//                     }
//                     if (vendorSnapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'Error: ${vendorSnapshot.error}',
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                       );
//                     }
//                     if ((!customerSnapshot.hasData ||
//                             customerSnapshot.data!.docs.isEmpty) &&
//                         (!vendorSnapshot.hasData ||
//                             vendorSnapshot.data!.docs.isEmpty)) {
//                       return const Center(
//                         child: Text(
//                           'No transactions found',
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       );
//                     }
//                     List<Map<String, dynamic>> allTransactions = [];
//                     if (customerSnapshot.hasData) {
//                       for (var doc in customerSnapshot.data!.docs) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         final timestamp = data['timestamp'] as Timestamp?;
//                         if (timestamp != null && _shouldInclude(timestamp)) {
//                           allTransactions.add({
//                             'type': 'Customer',
//                             'name': data['name'],
//                             'amount': data['paidNow'],
//                             'timestamp': timestamp,
//                             'color': Colors.blue,
//                             'balance': data['currentBill'] - data['paidNow'],
//                           });
//                         }
//                       }
//                     }
//                     if (vendorSnapshot.hasData) {
//                       for (var doc in vendorSnapshot.data!.docs) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         final timestamp = data['timestamp'] as Timestamp?;
//                         if (timestamp != null && _shouldInclude(timestamp)) {
//                           allTransactions.add({
//                             'type': 'Vendor',
//                             'name': data['name'],
//                             'amount': data['paidNow'],
//                             'timestamp': timestamp,
//                             'color': Colors.blue,
//                             'balance': data['currentBill'] - data['paidNow'],
//                           });
//                         }
//                       }
//                     }
//                     allTransactions.sort(
//                       (a, b) => b['timestamp'].compareTo(a['timestamp']),
//                     );
//                     return ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: allTransactions.length,
//                       itemBuilder: (context, index) {
//                         final transaction = allTransactions[index];
//                         final date = transaction['timestamp'].toDate();
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           child: ExpansionTile(
//                             leading: CircleAvatar(
//                               backgroundColor: Colors.blue.withOpacity(0.1),
//                               child: Icon(
//                                 transaction['type'] == 'Customer'
//                                     ? Icons.arrow_downward
//                                     : Icons.arrow_upward,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                             title: Text(
//                               transaction['name'],
//                               style: const TextStyle(color: Colors.black),
//                             ),
//                             subtitle: Text(
//                               '${transaction['type']} - ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}',
//                               style: const TextStyle(color: Colors.black54),
//                             ),
//                             trailing: Text(
//                               '﷼${transaction['amount'].toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Balance: ﷼${transaction['balance'].toStringAsFixed(2)}',
//                                       style: const TextStyle(
//                                         color: Colors.black,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String label, String value) {
//     return FilterChip(
//       label: Text(label, style: const TextStyle(color: Colors.black)),
//       selected: filterType == value,
//       onSelected: (selected) {
//         setState(() {
//           filterType = value;
//           if (value != 'custom') {
//             startDate = null;
//             endDate = null;
//           }
//         });
//       },
//       backgroundColor: Colors.white,
//       selectedColor: Colors.blue.withOpacity(0.2),
//       checkmarkColor: Colors.blue,
//       labelStyle: const TextStyle(color: Colors.black),
//     );
//   }

//   bool _shouldInclude(Timestamp timestamp) {
//     final date = timestamp.toDate();
//     final now = DateTime.now();
//     switch (filterType) {
//       case 'today':
//         return date.year == now.year &&
//             date.month == now.month &&
//             date.day == now.day;
//       case 'month':
//         return date.year == now.year && date.month == now.month;
//       case 'custom':
//         if (startDate != null && endDate != null) {
//           final start = DateTime(
//             startDate!.year,
//             startDate!.month,
//             startDate!.day,
//           );
//           final end = DateTime(
//             endDate!.year,
//             endDate!.month,
//             endDate!.day,
//             23,
//             59,
//             59,
//           );
//           return date.isAfter(
//                 start.subtract(const Duration(microseconds: 1)),
//               ) &&
//               date.isBefore(end.add(const Duration(microseconds: 1)));
//         }
//         return false;
//       default:
//         return true;
//     }
//   }
// }

// class InvoicePage extends StatelessWidget {
//   final String docId;
//   final Map<String, dynamic> data;
//   final String type;

//   const InvoicePage({
//     super.key,
//     required this.docId,
//     required this.data,
//     required this.type,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final balance = data['currentBill'] - data['paidNow'];
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Invoice', style: TextStyle(color: Colors.black)),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
//             onPressed: () => _generatePDF(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.share, color: Colors.blue),
//             onPressed: () => _shareInvoice(context),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'INVOICE',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const Divider(height: 32, color: Colors.blue),
//                     Text(
//                       'Name: ${data['name']}',
//                       style: const TextStyle(fontSize: 16, color: Colors.black),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Phone: ${data['phone']}',
//                       style: const TextStyle(fontSize: 16, color: Colors.black),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
//                       style: const TextStyle(fontSize: 16, color: Colors.black),
//                     ),
//                     const Divider(height: 32, color: Colors.blue),
//                     const Text(
//                       'Products:',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ...((data['products'] as List).map(
//                       (p) => Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               '${p['name']} x ${p['qty']}',
//                               style: const TextStyle(color: Colors.black),
//                             ),
//                             Text(
//                               '﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}',
//                               style: const TextStyle(color: Colors.black),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )),
//                     const Divider(height: 32, color: Colors.blue),
//                     _buildRow('Previous Balance', data['previousBalance']),
//                     _buildRow('Additional Charge', data['additionalCharge']),
//                     _buildRow('Discount', data['discount']),
//                     _buildRow('Tax', data['tax']),
//                     const Divider(height: 24, color: Colors.blue),
//                     _buildRow('Total Bill', data['currentBill'], isTotal: true),
//                     _buildRow('Paid Now', data['paidNow']),
//                     const Divider(height: 24, color: Colors.blue),
//                     _buildRow('Balance', balance, isBalance: true),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => _shareViaWhatsApp(context),
//                 icon: const Icon(Icons.share),
//                 label: const Text('Share via WhatsApp'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRow(
//     String label,
//     dynamic value, {
//     bool isTotal = false,
//     bool isBalance = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal || isBalance ? 18 : 16,
//               fontWeight: isTotal || isBalance
//                   ? FontWeight.bold
//                   : FontWeight.normal,
//               color: Colors.black,
//             ),
//           ),
//           Text(
//             '﷼${value.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: isTotal || isBalance ? 18 : 16,
//               fontWeight: isTotal || isBalance
//                   ? FontWeight.bold
//                   : FontWeight.normal,
//               color: Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _generatePDF(BuildContext context) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               'INVOICE',
//               style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Text('Name: ${data['name']}'),
//             pw.Text('Phone: ${data['phone']}'),
//             pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
//             pw.SizedBox(height: 20),
//             pw.Text(
//               'Products:',
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//             ),
//             ...((data['products'] as List).map(
//               (p) => pw.Text(
//                 '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}',
//               ),
//             )),
//             pw.SizedBox(height: 20),
//             pw.Text('Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}'),
//             pw.Text('Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}'),
//             pw.Text(
//               'Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}',
//             ),
//           ],
//         ),
//       ),
//     );
//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Future<void> _shareInvoice(BuildContext context) async {
//     final text =
//         '''
// Invoice
// Name: ${data['name']}
// Phone: ${data['phone']}
// Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
// Products:
// ${(data['products'] as List).map((p) => '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}').join('\n')}
// Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}
// Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}
// Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}
// ''';
//     await Share.share(text);
//   }

//   Future<void> _shareViaWhatsApp(BuildContext context) async {
//     final text =
//         '''
// Invoice
// Name: ${data['name']}
// Phone: ${data['phone']}
// Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
// Products:
// ${(data['products'] as List).map((p) => '${p['name']} x ${p['qty']} - ﷼${(p['rate'] * p['qty']).toStringAsFixed(2)}').join('\n')}
// Total Bill: ﷼${data['currentBill'].toStringAsFixed(2)}
// Paid Now: ﷼${data['paidNow'].toStringAsFixed(2)}
// Balance: ﷼${(data['currentBill'] - data['paidNow']).toStringAsFixed(2)}
// ''';
//     final phone = data['phone'].replaceAll(RegExp(r'[^\d+]'), '');
//     final url = Uri.parse(
//       'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
//     );
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     }
//   }
// }

// class ProductSelectionPage extends StatefulWidget {
//   final List<Map<String, dynamic>> selectedProducts;

//   const ProductSelectionPage({super.key, required this.selectedProducts});

//   @override
//   State<ProductSelectionPage> createState() => _ProductSelectionPageState();
// }

// class _ProductSelectionPageState extends State<ProductSelectionPage> {
//   List<Map<String, dynamic>> tempSelected = [];

//   @override
//   void initState() {
//     super.initState();
//     tempSelected = List.from(widget.selectedProducts);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Select Products',
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('products').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No products available',
//                 style: TextStyle(color: Colors.black),
//               ),
//             );
//           }
//           final products = snapshot.data!.docs;
//           return ListView.builder(
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index].data() as Map<String, dynamic>;
//               final isSelected = tempSelected.any(
//                 (p) => p['name'] == product['name'],
//               );
//               return CheckboxListTile(
//                 title: Text(
//                   product['name'],
//                   style: const TextStyle(color: Colors.black),
//                 ),
//                 subtitle: Text(
//                   '﷼${product['price']}',
//                   style: const TextStyle(color: Colors.black),
//                 ),
//                 value: isSelected,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     if (value == true) {
//                       tempSelected.add({
//                         'name': product['name'],
//                         'rate': product['price'],
//                         'qty': 1,
//                       });
//                     } else {
//                       tempSelected.removeWhere(
//                         (p) => p['name'] == product['name'],
//                       );
//                     }
//                   });
//                 },
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => Navigator.pop(context, tempSelected),
//         child: const Icon(Icons.done),
//       ),
//     );
//   }
// }
