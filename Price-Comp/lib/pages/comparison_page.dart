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
  Set<String> selectedRetailers = {'r1', 'r2'};

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
    final prices = _prices
        .where(
          (p) => p.price != null && selectedRetailers.contains(p.retailerId),
        )
        .map((p) => p.price!)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  @override
  Widget build(BuildContext context) {
    final best = getBestPrice();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compare'),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      child: const Icon(Icons.image, size: 64),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.product.size} • ${widget.product.category}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Avg mock price: R ${MockDatabase.getMockPrice(widget.product.id).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                        if (v)
                          selectedRetailers.add(id);
                        else
                          selectedRetailers.remove(id);
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? ListView.builder(
                        itemCount: 4,
                        itemBuilder: (_, __) => const RetailerPlaceholder(),
                      )
                    : _error != null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Something went wrong',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                ),
                                onPressed: () => _loadComparison(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _prices
                          .where(
                            (p) => selectedRetailers.contains(p.retailerId),
                          )
                          .isEmpty
                    ? const Center(child: Text('No comparison data available'))
                    : ListView.separated(
                        itemCount: _prices
                            .where(
                              (p) => selectedRetailers.contains(p.retailerId),
                            )
                            .length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final list = _prices
                              .where(
                                (p) => selectedRetailers.contains(p.retailerId),
                              )
                              .toList();
                          final item = list[idx];
                          final isBest =
                              item.price != null &&
                              best != null &&
                              (item.price! - best).abs() < 0.001;
                          return RetailerCard(price: item, highlight: isBest);
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proceed to purchase (future)'),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}
