import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../models/item_analysis_result.dart';
import '../models/item_category.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  static const _pageSize = 20;
  final List<ItemAnalysisResult> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final data = (await widget.appState.api.getAnalysisHistory(
        page: reset ? 1 : _page + 1,
        limit: _pageSize,
      ) as Map).cast<String, dynamic>();
      final rows = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (row) =>
                ItemAnalysisResult.fromApiJson(row.cast<String, dynamic>()),
          )
          .toList(growable: false);
      final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(rows);
        _page = reset ? 1 : _page + 1;
        _hasMore = pagination == null
            ? rows.length == _pageSize
            : _page < ((pagination['totalPages'] as num?)?.toInt() ?? _page);
        _error = null;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) await widget.appState.logout();
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Saved analyses could not be loaded. Please retry.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  String _dateLabel(BuildContext context, DateTime? value) => value == null
      ? 'Date unavailable'
      : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const ReCircleBrandTitle('Analysis History')),
    body: _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _items.isEmpty
        ? _HistoryMessage(
            icon: Icons.cloud_off_outlined,
            title: 'History unavailable',
            message: _error!,
            action: () => _load(reset: true),
          )
        : _items.isEmpty
        ? RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 130),
                Icon(
                  Icons.manage_search,
                  size: 56,
                  color: AppTheme.primaryGreen,
                ),
                SizedBox(height: 12),
                Center(child: Text('No saved analyses yet')),
                SizedBox(height: 6),
                Center(child: Text('Analyze an item and it will appear here.')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + (_hasMore || _error != null ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  if (_error != null) {
                    return TextButton.icon(
                      onPressed: () => _load(reset: false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Could not load more. Retry'),
                    );
                  }
                  return Center(
                    child: TextButton(
                      onPressed: _loadingMore
                          ? null
                          : () => _load(reset: false),
                      child: _loadingMore
                          ? const CircularProgressIndicator()
                          : const Text('Load more'),
                    ),
                  );
                }
                final item = _items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.accentLightGreen,
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    title: Text(
                      item.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${_categoryLabel(item.category)} · ${item.confidence == null ? 'Confidence unavailable' : '${(item.confidence! * 100).round()}% confidence'}\n${_dateLabel(context, item.analyzedAt)}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.analysisId == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AnalysisDetailScreen(
                                appState: widget.appState,
                                analysisId: item.analysisId!,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
  );

  String _categoryLabel(ItemCategory value) => switch (value) {
    ItemCategory.mixedMaterials => 'Mixed materials',
    ItemCategory.unknown => 'Category unavailable',
    _ => value.name[0].toUpperCase() + value.name.substring(1),
  };
}

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({
    super.key,
    required this.appState,
    required this.analysisId,
  });

  final AppState appState;
  final String analysisId;

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  ItemAnalysisResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = (await widget.appState.api.getAnalysisDetail(
        widget.analysisId,
      ) as Map).cast<String, dynamic>();
      if (mounted) {
        setState(() => _result = ItemAnalysisResult.fromApiJson(data));
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) await widget.appState.logout();
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'This saved analysis could not be opened. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const ReCircleBrandTitle('Saved Analysis')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _HistoryMessage(
            icon: Icons.error_outline,
            title: 'Could not open analysis',
            message: _error!,
            action: _load,
          )
        : _buildResult(_result!),
  );

  Widget _buildResult(ItemAnalysisResult result) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(result.itemName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(
        '${result.category.label} · ${result.analyzedAt == null ? 'Date unavailable' : MaterialLocalizations.of(context).formatMediumDate(result.analyzedAt!.toLocal())}',
      ),
      const SizedBox(height: 18),
      _section(
        'Confidence',
        result.confidence == null
            ? 'Unavailable'
            : '${(result.confidence! * 100).round()}% · visual estimate',
      ),
      _section(
        'Visible condition',
        result.visibleCondition ?? 'Unclear from this image',
      ),
      _section(
        'Likely materials',
        result.likelyMaterials.isEmpty
            ? 'Not clear from the image'
            : result.likelyMaterials.join(', '),
      ),
      _section('Analysis', result.explanation),
      if (result.uncertaintyNotes.isNotEmpty)
        _section(
          'Uncertainty',
          result.uncertaintyNotes.map((entry) => '• $entry').join('\n'),
        ),
      if (result.safetyNotes.isNotEmpty)
        _section(
          'Safety notes',
          result.safetyNotes.map((entry) => '• $entry').join('\n'),
        ),
      _section(
        result.reusable ? 'Reuse First' : 'Recycling recommendation',
        result.reusable
            ? 'Reuse may be practical based on visible details.'
            : result.recyclingRecommendation,
      ),
      if (result.reuseSuggestions.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Reuse ideas', style: Theme.of(context).textTheme.titleLarge),
        for (final idea in result.reuseSuggestions)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(idea.shortDescription),
                  if (idea.materialsNeeded.isNotEmpty)
                    Text('Materials: ${idea.materialsNeeded.join(', ')}'),
                  for (var i = 0; i < idea.steps.length; i++)
                    Text('${i + 1}. ${idea.steps[i]}'),
                ],
              ),
            ),
          ),
      ],
      const SizedBox(height: 12),
      const Text(
        'Visual estimates can be wrong. Confirm item function and local recycling guidance before acting.',
      ),
    ],
  );

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(body),
      ],
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
