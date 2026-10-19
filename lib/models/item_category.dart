enum ItemCategory {
  plastic,
  paper,
  cardboard,
  glass,
  metal,
  electronics,
  textiles,
  mixedMaterials,
  unknown,
}

extension ItemCategoryLabel on ItemCategory {
  String get label => switch (this) {
    ItemCategory.plastic => 'Plastic',
    ItemCategory.paper => 'Paper',
    ItemCategory.cardboard => 'Cardboard',
    ItemCategory.glass => 'Glass',
    ItemCategory.metal => 'Metal',
    ItemCategory.electronics => 'Electronics / E-waste',
    ItemCategory.textiles => 'Textiles',
    ItemCategory.mixedMaterials => 'Mixed materials',
    ItemCategory.unknown => 'Unknown',
  };
}
