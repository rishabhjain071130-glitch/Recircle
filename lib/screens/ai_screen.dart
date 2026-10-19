import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/widgets/app_state_view.dart';
import '../features/analysis/data/backend_item_analysis_service.dart';
import '../features/analysis/data/item_analysis_service.dart';
import '../features/requests/data/recircle_api.dart';
import '../features/scan/data/image_capture_service.dart';
import '../models/item_analysis_result.dart';
import '../models/item_category.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/reuse_card.dart';
import '../widgets/recircle_branding.dart';
import 'pickup_booking_screen.dart';
import 'reuse_detail_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({
    super.key,
    required this.appState,
    this.initialActionMode,
    this.initialImage,
    this.initialError,
    this.imageCaptureService,
    this.analysisService,
  });

  final AppState appState;
  final String? initialActionMode;
  final XFile? initialImage;
  final String? initialError;
  final ImageCaptureService? imageCaptureService;
  final ItemAnalysisService? analysisService;

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  late final ImageCaptureService _imageCapture =
      widget.imageCaptureService ?? PlatformImageCaptureService();
  late final ItemAnalysisService _analysisService =
      widget.analysisService ?? BackendItemAnalysisService(widget.appState.api);

  XFile? _image;
  ItemAnalysisResult? _result;
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
    _error = widget.initialError;
    _handleInitialAction(widget.initialActionMode);
  }

  @override
  void didUpdateWidget(covariant AIScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != oldWidget.initialImage &&
        widget.initialImage != null) {
      _image = widget.initialImage;
      _result = null;
      _error = widget.initialError;
      _isBusy = false;
    }
    if (widget.initialError != oldWidget.initialError &&
        widget.initialError != null) {
      _error = widget.initialError;
      _image = null;
      _result = null;
      _isBusy = false;
    }
    if (widget.initialActionMode != oldWidget.initialActionMode &&
        widget.initialActionMode != null) {
      _handleInitialAction(widget.initialActionMode);
    }
  }

  void _handleInitialAction(String? mode) {
    if (mode == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chooseImage(
        mode == 'gallery' ? ImageSource.gallery : ImageSource.camera,
      );
    });
  }

  Future<void> _chooseImage(ImageSource source) async {
    setState(() {
      _isBusy = true;
      _error = null;
      _result = null;
      _image = null;
    });

    try {
      final image = await _imageCapture.captureOrChoose(source);
      if (!mounted) return;
      if (image == null) {
        setState(() => _isBusy = false);
        return;
      }
      setState(() => _image = image);
      setState(() => _isBusy = false);
    } on ImageSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = 'We could not open that image. Try another photo or choose a different source.';
      });
    }
  }

  Future<void> _analyze(XFile image, {ItemCategory? category}) async {
    setState(() {
      _isBusy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _analysisService.analyze(
        image: image,
        manualCategory: category,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = error is ApiException
            ? error.message
            : 'Analysis did not finish. Retry with this image.';
      });
    }
  }

  Future<void> _chooseCategoryManually() async {
    final category = await showModalBottomSheet<ItemCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Choose a category'),
              subtitle: Text(
                'Use this correction and ask the analyzer to review the photo again.',
              ),
            ),
            for (final category in ItemCategory.values.where(
              (category) => category != ItemCategory.unknown,
            ))
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(category.label),
                onTap: () => Navigator.pop(context, category),
              ),
          ],
        ),
      ),
    );
    if (category != null && _image != null) {
      await _analyze(_image!, category: category);
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _error = null;
      _isBusy = false;
    });
  }

  void _openReuseGuide(int index) {
    final result = _result;
    if (result == null || result.reuseSuggestions.isEmpty) return;
    final idea = result.reuseSuggestions[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReuseDetailScreen(idea: idea, appState: widget.appState),
      ),
    );
  }

  void _openPickup() {
    final result = _result;
    if (result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupBookingScreen(
          appState: widget.appState,
          initialItemName: result.itemName,
          initialCategory: switch (result.category) {
            ItemCategory.plastic => 'Plastic',
            ItemCategory.paper || ItemCategory.cardboard => 'Paper',
            ItemCategory.glass => 'Other',
            ItemCategory.metal => 'Metal',
            ItemCategory.electronics => 'E-Waste',
            ItemCategory.textiles ||
            ItemCategory.mixedMaterials ||
            ItemCategory.unknown => 'Other',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const ReCircleBrandTitle('Scan an Item'),
        actions: [
          if (_image != null)
            TextButton(onPressed: _reset, child: const Text('New scan')),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Give your item a second chance.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a photo or choose one from your gallery. ReCircle will analyze visible details and suggest reuse first.',
                style: TextStyle(color: AppTheme.subtitleGrey),
              ),
              const SizedBox(height: 18),
              if (_image == null) _buildPickerCard(),
              if (_image != null) _buildImagePreview(_image!),
              if (_image != null && result == null && !_isBusy) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _analyze(_image!),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Analyze Item'),
                  ),
                ),
              ],
              if (_isBusy) ...[
                const SizedBox(height: 16),
                const AppLoadingView(message: 'Analyzing your item…'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                AppMessageView(
                  title: _error!.contains('declined')
                      ? 'Permission denied'
                      : 'Could not use this image',
                  message: _error!,
                  icon: _error!.contains('declined')
                      ? Icons.no_photography_outlined
                      : Icons.warning_amber_outlined,
                  actionLabel: _image == null
                      ? 'Choose from gallery'
                      : 'Retry analysis',
                  action: _image == null
                      ? () => _chooseImage(ImageSource.gallery)
                      : () => _analyze(_image!),
                ),
              ],
              if (result != null) ...[
                const SizedBox(height: 16),
                _buildResult(result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.pureWhite,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.borderGrey),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.accentLightGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.center_focus_strong,
            color: AppTheme.primaryGreen,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'What would you like help with?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Take a photo or choose one from your gallery.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.subtitleGrey),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : () => _chooseImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take Photo'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _chooseImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from Gallery'),
          ),
        ),
      ],
    ),
  );

  Widget _buildImagePreview(XFile image) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(
      constraints: const BoxConstraints(maxHeight: 280),
      color: AppTheme.accentLightGreen,
      child: Image.file(
        File(image.path),
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const AppMessageView(
          title: 'Preview unavailable',
          message: 'The selected image could not be displayed. Choose another image.',
        ),
      ),
    ),
  );

  Widget _buildResult(ItemAnalysisResult result) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentLightGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.analysisKind == AnalysisKind.mock
                        ? 'Sample analysis · demo data'
                        : 'Analysis result',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (result.analysisKind == AnalysisKind.mock)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Image contents are not interpreted by a real AI model yet.',
                  style: TextStyle(color: AppTheme.subtitleGrey, fontSize: 12),
                ),
              ),
            Text(
              result.itemName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _detailRow('Category', result.category.label),
            _detailRow(
              'Likely materials',
              result.likelyMaterials.isEmpty
                  ? result.material
                  : result.likelyMaterials.join(', '),
            ),
            _detailRow(
              'Confidence',
              result.confidence == null
                  ? 'Category chosen manually'
                  : '${(result.confidence! * 100).round()}% · visual estimate',
            ),
            _detailRow(
              'Visible condition',
              result.visibleCondition ??
                  switch (result.condition) {
                    ItemCondition.reusable =>
                      'Reusable appearance; function not verified',
                    ItemCondition.damaged => 'Visible damage',
                    ItemCondition.unknown => 'Unclear from this photo',
                    ItemCondition.notAssessed => 'Not assessed',
                  },
            ),
            const SizedBox(height: 8),
            Text(result.explanation, style: const TextStyle(fontSize: 12)),
            if (result.uncertaintyNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Uncertainty',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final note in result.uncertaintyNotes) Text('• $note'),
            ],
            if (result.safetyNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Safety notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final note in result.safetyNotes) Text('• $note'),
            ],
          ],
        ),
      ),
      if (result.needsManualCategory) ...[
        const SizedBox(height: 12),
        AppMessageView(
          title: "I'm not sure what this item is",
          message: 'If the category looks wrong, select the closest match and retry.',
          icon: Icons.help_outline,
          actionLabel: 'Choose Category Manually',
          action: _chooseCategoryManually,
        ),
      ],
      const SizedBox(height: 16),
      Text(
        result.reusable ? 'Reuse First' : 'Recycling may be the better option',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        result.reusable
            ? 'Reuse may be practical based on visible details. Check the item’s actual function and safety before reuse.'
            : result.recyclingRecommendation,
      ),
      if (result.reuseSuggestions.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text(
          'Reuse ideas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < result.reuseSuggestions.length; index++)
          ReuseCard(
            idea: result.reuseSuggestions[index],
            onViewGuide: () => _openReuseGuide(index),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openReuseGuide(0),
            icon: const Icon(Icons.eco_outlined),
            label: const Text('Use a Reuse Idea'),
          ),
        ),
      ],
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: result.reusable
            ? OutlinedButton.icon(
                onPressed: _openPickup,
                icon: const Icon(Icons.recycling_outlined),
                label: const Text('Recycle Instead'),
              )
            : ElevatedButton.icon(
                onPressed: _openPickup,
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Explore Pickup Options'),
              ),
      ),
      const SizedBox(height: 8),
      Text(
        result.analysisKind == AnalysisKind.mock
            ? 'Sample suggestions only; the image was not interpreted by AI.'
            : 'Visual estimates can be wrong. Confirm item function and local recycling guidance before acting.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppTheme.subtitleGrey),
      ),
    ],
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
