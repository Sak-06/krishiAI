import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../localization/app_translations.dart';
import '../main.dart';
import 'login_screen.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Text(
          AppTranslations.text(context, 'buyer_dashboard'),
        ),
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
          IconButton(
            icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false, // removes ALL previous routes
                );
              },

          ),
        ],
      ),
      backgroundColor: Colors.green.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Firestore error: ${snapshot.error}");
            return _buildErrorState(context, snapshot.error.toString());
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildProductGrid(products, context);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.text(context, 'connection issue'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),

            child: Text(
              AppTranslations.text(context, 'Unable to load products. Please check your connection and try again.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Retry loading
            },
            child: Text(AppTranslations.text(context,"Retry")),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            AppTranslations.text(context,'no_products'),
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            AppTranslations.text(context,'check_back,later'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<QueryDocumentSnapshot> products, BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productData = product.data() as Map<String, dynamic>;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket,
                    size: 48, color: Colors.green),
                const SizedBox(height: 8),
                Text(
                  productData['name'] ?? 'Product',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "₹${productData['price'] ?? '0'} per kg",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(product.id)
                        .collection('offers')
                        .add({
                      'buyerId': user!.uid,
                      'buyerName': user.displayName ?? 'Buyer',
                      'offeredPrice': productData['price'],
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Offer sent successfully"))
                    );
                  },
                  child: const Text("Send Offer"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}