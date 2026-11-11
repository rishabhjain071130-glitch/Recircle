/// Category-level average product weights used for demo impact estimates.
/// These values are estimates, not physical measurements.
class EwasteWeightEstimates {
  const EwasteWeightEstimates._();

  static const Map<String, double> kilogramsByCategory = {
    'phone/mobile': 0.1,
    'tablet': 0.6,
    'laptop/notebook': 2.9,
    'desktop': 10.0,
    'monitor': 11.2,
    'tv/television': 9.8,
    'printer/scanner': 7.9,
    'keyboard': 1.3,
    'mouse': 0.1,
    'battery': 0.5,
    'cable/accessory': 0.2,
    'unknown/fallback': 1.0,
  };

  static double estimateKg({required String category, String itemName = ''}) {
    final value = '$itemName $category'.toLowerCase();
    if (value.contains('phone') || value.contains('mobile')) return 0.1;
    if (value.contains('tablet')) return 0.6;
    if (value.contains('laptop') || value.contains('notebook')) return 2.9;
    if (value.contains('desktop')) return 10.0;
    if (value.contains('monitor')) return 11.2;
    if (value.contains('tv') || value.contains('television')) return 9.8;
    if (value.contains('printer') || value.contains('scanner')) return 7.9;
    if (value.contains('keyboard')) return 1.3;
    if (value.contains('mouse')) return 0.1;
    if (value.contains('battery')) return 0.5;
    if (value.contains('cable') || value.contains('accessory')) return 0.2;
    return kilogramsByCategory['unknown/fallback']!;
  }
}
