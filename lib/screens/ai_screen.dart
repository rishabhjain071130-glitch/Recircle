import 'package:flutter/material.dart';
import '../models/recycling_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/reuse_card.dart';
import 'pickup_booking_screen.dart';
import 'reuse_detail_screen.dart';

class AIScreen extends StatefulWidget {
  final AppState appState;
  final String? initialActionMode; // 'camera' or 'gallery' or null

  const AIScreen({
    super.key,
    required this.appState,
    this.initialActionMode,
  });

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  RecyclingItem? _selectedItem;
  bool _isAnalyzing = false;
  String? _modeUsed;

  @override
  void initState() {
    super.initState();
    if (widget.initialActionMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _simulateScan(widget.initialActionMode == 'camera' ? 'Camera' : 'Gallery', RecyclingItem.sampleItems.first);
      });
    }
  }

  void _simulateScan(String sourceName, RecyclingItem item) {
    setState(() {
      _isAnalyzing = true;
      _modeUsed = sourceName;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _selectedItem = item;
        });
      }
    });
  }

  void _resetScan() {
    setState(() {
      _selectedItem = null;
      _modeUsed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sampleItems = RecyclingItem.sampleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReCircle AI'),
        actions: [
          if (_selectedItem != null)
            TextButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('New Scan'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ReCircle AI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Discover what your unwanted items can become.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Scanning Box or Result View
            if (_isAnalyzing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Analyzing item via $_modeUsed...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Identifying material & calculating reuse possibilities',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              )
            else if (_selectedItem == null) ...[
              // Upload / Scan Drop Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentLightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: AppTheme.primaryGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan or Upload an Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Take a picture or select an existing photo to analyze recycling or reuse options.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtitleGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _simulateScan('Camera', sampleItems.first);
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Use Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _simulateScan('Gallery', sampleItems.first);
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Demo quick items picker
              const Text(
                'Or try with sample items:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sampleItems.length,
                itemBuilder: (context, index) {
                  final item = sampleItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category, color: AppTheme.primaryGreen),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      subtitle: Text(
                        'Category: ${item.category} • ${item.reuseIdeas.length} ideas',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                      onTap: () {
                        _simulateScan('Demo Selector', item);
                      },
                    ),
                  );
                },
              ),
            ] else ...[
              // AI Result Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.accentLightGreen.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Identified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          Text(
                            _selectedItem!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            'Category: ${_selectedItem!.category}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtitleGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Here's what you can do with it:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore upcycling DIY guides or book a pickup for recycling.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.subtitleGrey,
                ),
              ),

              const SizedBox(height: 16),

              // List of Reuse Cards
              ..._selectedItem!.reuseIdeas.map((idea) {
                return ReuseCard(
                  idea: idea,
                  onViewGuide: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReuseDetailScreen(
                          idea: idea,
                          appState: widget.appState,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),

              const SizedBox(height: 16),

              // Recycle Instead Card / Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Not suitable for reuse?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'If the item is broken or worn out, send it directly for safe recycling.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtitleGrey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PickupBookingScreen(
                                appState: widget.appState,
                                initialItemName: _selectedItem!.name,
                                initialCategory: _selectedItem!.category,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Recycle Instead'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
