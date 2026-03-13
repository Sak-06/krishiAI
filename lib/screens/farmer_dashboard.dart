import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:krashi_ai/localization/app_translations.dart';

import '../main.dart';
import 'login_screen.dart';
import 'smart_listing_screen.dart';
import 'price_prediction_screen.dart';
import 'crop_analysis_screen.dart';
// import 'chatbot_screen.dart'; // add later

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({Key? key}) : super(key: key);

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Text(AppTranslations.text(context,'farmer_dashboard')),
        actions: [
          // 🌍 Language Selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              if (value == 'en') {
                DirectMarketApp.of(context)
                    ?.setLocale(const Locale('en'));
              } else {
                DirectMarketApp.of(context)
                    ?.setLocale(const Locale('hi'));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'en',
                child: Text("English"),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text("हिंदी"),
              ),
            ],
          ),

          // 💬 Message Icon (if you added chat list)
          /// 💬 Messages (future negotiation/chat)
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),

          /// 🚪 Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
          ),
        ],
      ),

      backgroundColor: Colors.green.shade50,

      body: _currentIndex == 0
          ? _buildDashboard(user)
          : _buildBottomPage(),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: Text(AppTranslations.text(context, 'add_product')),
        onPressed: () => _showAddProductDialog(context),
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "Smart List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Price AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: "Crop AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "Chat AI",
          ),
        ],
      ),
    );
  }

  // ================= DASHBOARD =================

  Widget _buildDashboard(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('farmerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data?.docs ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text(
              "No products listed yet.\nAdd your first product!",
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (_, index) => _buildProductCard(products[index]),
        );
      },
    );
  }

  // ================= PRODUCT CARD =================

  Widget _buildProductCard(DocumentSnapshot product) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .doc(product.id)
          .collection('offers')
          .snapshots(),
      builder: (context, snapshot) {
        final offerCount = snapshot.data?.docs.length ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const Icon(Icons.local_florist, color: Colors.green),
            title: Text(
              product['name'] ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("₹${product['price']} per kg"),
            trailing: Chip(
              label: Text("$offerCount Offers"),
              backgroundColor: offerCount > 0
                  ? Colors.orange.shade100
                  : Colors.grey.shade300,
            ),
            onTap: () => _openOffersSheet(product.id),
          ),
        );
      },
    );
  }

  // ================= OFFERS BOTTOM SHEET =================

  void _openOffersSheet(String productId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('products')
              .doc(productId)
              .collection('offers')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final offers = snapshot.data?.docs ?? [];

            if (offers.isEmpty) {
              return const Center(child: Text("No offers yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (_, index) {
                final offer = offers[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(offer['buyerName'] ?? 'Buyer'),
                    subtitle:
                    Text("Offered ₹${offer['offeredPrice']} per kg"),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= ADD PRODUCT =================

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _productController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price per kg"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _productController.text.trim();
              final price = _priceController.text.trim();

              if (name.isEmpty || price.isEmpty) return;

              await _firestore.collection('products').add({
                'name': name,
                'price': double.tryParse(price) ?? 0,
                'farmerId': _auth.currentUser!.uid,
                // ✅ FIX: local timestamp (no disappearing)
                'timestamp': Timestamp.now(),
              });

              _productController.clear();
              _priceController.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM NAV PAGES =================

  Widget _buildBottomPage() {
    switch (_currentIndex) {
      case 1:
        return const SmartListingScreen();
      case 2:
        return const PricePredictionScreen();
      //case 3:
        return const CropAnalysisScreen();
      case 4:
        return const Center(child: Text("AI Chatbot Coming Soon"));
      default:
        return const SizedBox();
    }
  }
}
