import 'recycling_item.dart';

enum AnalysisSource { demo, userProvided }

class ItemAnalysis {
  const ItemAnalysis({
    required this.item,
    required this.source,
    this.confidence,
    this.analyzedAt,
  }) : assert(confidence == null || (confidence >= 0 && confidence <= 1));

  final RecyclingItem item;
  final AnalysisSource source;
  final double? confidence;
  final DateTime? analyzedAt;

  bool get isEstimated => source == AnalysisSource.demo || confidence != null;

  Map<String, Object?> toJson() => {
    'item': item.toJson(),
    'source': source.name,
    'confidence': confidence,
    'analyzedAt': analyzedAt?.toIso8601String(),
  };
}
