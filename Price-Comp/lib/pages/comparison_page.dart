import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../models/retailer_price.dart';
import '../widgets/retailer_card.dart';
import '../widgets/retailer_placeholder.dart';

class ComparisonPage extends StatefulWidget {
  final Product product;
  const ComparisonPage({required this.product});

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  List<RetailerPrice> _prices = [];
  bool _loading = true;
  String? _error;
  Set<String> selectedRetailers = {'r1', 'r2', 'r3', 'r4'};

  @override
  void initState() {
    super.initState();
    debugPrint('[ComparisonPage] started for ${widget.product.id}');
    _loadComparison();
  }

  @override
  void dispose() {
    debugPrint('[ComparisonPage] stopped for ${widget.product.id}');
    super.dispose();
  }

  Future<void> _loadComparison({
    bool partial = false,
    bool fail = false,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MockDatabase.getComparison(
        widget.product.id,
        partial: partial,
        fail: fail,
      );
      setState(() => _prices = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  double? getBestPrice() {
    final filteredPrices = _getFilteredPrices();
    final prices = filteredPrices
        .where((p) => p.price != null)
        .map((p) => p.price!)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  List<RetailerPrice> _getFilteredPrices() {
    return _prices
        .where((p) => selectedRetailers.contains(p.retailerId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrices = _getFilteredPrices();
    final best = getBestPrice();

    return Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Column(
        children: [
          // Header matching the design
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            color: Color(0xFF2563EB),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16),
                Text(
                  'Price Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Product List Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Product Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage('assets/product_image.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: TextStyle(
                                    color: Color(0xFF3D3D3D),
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${widget.product.size} • ${widget.product.category}',
                                  style: TextStyle(
                                    color: Color(0xFF3D3D3D),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Retailer Filter Chips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: MockDatabase.retailers.map((r) {
                          final id = r['id']!;
                          final name = r['name']!;
                          final sel = selectedRetailers.contains(id);
                          return FilterChip(
                            label: Text(name),
                            selected: sel,
                            onSelected: (v) => setState(() {
                              if (v) {
                                selectedRetailers.add(id);
                              } else {
                                selectedRetailers.remove(id);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Retailer List
                    Expanded(
                      child: _loading
                          ? ListView.builder(
                              itemCount: 4,
                              itemBuilder: (_, __) =>
                                  const RetailerPlaceholder(),
                            )
                          : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Error: $_error'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _loadComparison(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredPrices.isEmpty
                          ? const Center(
                              child: Text('No comparison data available'),
                            )
                          : ListView.separated(
                              itemCount: filteredPrices.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final item = filteredPrices[idx];
                                final isBest =
                                    item.price != null &&
                                    best != null &&
                                    (item.price! - best).abs() < 0.001;

                                return _buildRetailerCard(item, isBest);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceed to purchase (future)')),
                ),
                child: const Text('Proceed'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _loadComparison(partial: true),
              child: const Text('Load Partial'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetailerCard(RetailerPrice price, bool isBest) {
    // Enhanced retailer mapping with better ID matching
    final Map<String, Map<String, String>> retailerMapping = {
      'r2': {
        // Checkers
        'logo': 'assets/checkers.png',
        'name': 'Checkers',
      },
      'r3': {
        // Woolworths
        'logo': 'assets/woolworths.png',
        'name': 'Woolworths',
      },
      'r1': {
        // Pick n Pay
        'logo': 'assets/picknpay.png',
        'name': 'Pick n Pay',
      },
      'r4': {
        // Game
        'logo': 'assets/game.png',
        'name': 'Game',
      },
    };

    // Try to get retailer info from mapping
    final retailerInfo =
        retailerMapping[price.retailerId] ?? retailerMapping['r4']!;
    final String logoAsset = retailerInfo['logo']!;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isBest
            ? Color(0xFFEFF6FF)
            : Colors.white, // Highlight lowest price with light blue background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: isBest
            ? Border.all(
                // Add border for lowest price
                color: Color(0xFF2563EB),
                width: 2,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage('assets/product_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Retailer and Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Retailer Logo ONLY (no name) - BIGGER
                Container(
                  width: 90,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(
                      image: AssetImage(logoAsset),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                // Product Name
                Text(
                  widget.product.name,
                  style: TextStyle(
                    color: Color(0xFF3D3D3D),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1),
                // Price - Highlight lowest price
                Text(
                  price.price != null
                      ? 'R${price.price!.toStringAsFixed(2)}'
                      : 'Price not available',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: isBest ? 18 : 16, // Make lowest price larger
                    fontFamily: 'Inter',
                    fontWeight: isBest
                        ? FontWeight.w800
                        : FontWeight.w700, // Make lowest price bolder
                  ),
                ),
              ],
            ),
          ),
          // Lowest Price Badge - Changed to "Lowest"
          if (isBest && price.price != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Lowest', // Changed from "Best Price" to "Lowest"
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
