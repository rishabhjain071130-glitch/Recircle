import 'reuse_idea.dart';

class RecyclingItem {
  final String id;
  final String name;
  final String category; // Plastic, E-Waste, Paper, Metal, Other
  final String description;
  final String iconName;
  final List<ReuseIdea> reuseIdeas;

  bool get canBeReused => reuseIdeas.isNotEmpty;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'iconName': iconName,
    'reuseIdeas': reuseIdeas.map((idea) => idea.toJson()).toList(),
  };

  factory RecyclingItem.fromJson(Map<String, Object?> json) => RecyclingItem(
    id: json['id']! as String,
    name: json['name']! as String,
    category: json['category']! as String,
    description: json['description']! as String,
    iconName: json['iconName'] as String? ?? 'category',
    reuseIdeas: (json['reuseIdeas'] as List<Object?>? ?? const [])
        .map((idea) => ReuseIdea.fromJson(idea! as Map<String, Object?>))
        .toList(growable: false),
  );

  const RecyclingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.iconName,
    required this.reuseIdeas,
  });

  static final List<RecyclingItem> sampleItems = List.unmodifiable([
    RecyclingItem(
      id: 'item_plastic_bottle',
      name: 'Plastic Bottle',
      category: 'Plastic',
      description:
          'PET Polyethylene plastic container widely used for beverages.',
      iconName: 'local_drink',
      reuseIdeas: [
        const ReuseIdea(
          id: 'idea_flower_pot',
          title: 'Mini Flower Pot',
          shortDescription: 'Cut the bottle top and turn it into a cute indoor plant container.',
          category: 'Plastic',
          difficulty: 'Easy',
          timeRequired: '15 mins',
          materialsNeeded: [
            '1 Plastic Bottle',
            'Scissors or Utility Knife',
            'Acrylic Paint or Markers',
            'Potting Soil & Seedling',
            'Small drill or pin for drainage holes',
          ],
          steps: [
            'Clean the bottle thoroughly with warm water and soap.',
            'Carefully cut off the top third of the bottle using scissors.',
            'Poke 3-4 small drainage holes in the bottom base.',
            'Decorate the outer surface with paint or eco-friendly stickers.',
            'Add potting soil, place your seedling, and water gently.',
          ],
          iconName: 'local_florist',
        ),
        const ReuseIdea(
          id: 'idea_desk_organizer',
          title: 'Desk Organizer',
          shortDescription: 'Section bottle bottoms to keep pens, paper clips, and stationery sorted.',
          category: 'Plastic',
          difficulty: 'Easy',
          timeRequired: '10 mins',
          materialsNeeded: [
            '2 Plastic Bottles',
            'Scissors',
            'Washi Tape or Ribbon',
          ],
          steps: [
            'Clean and dry the bottles completely.',
            'Cut bottles at varying heights (3-5 inches from bottom).',
            'Cover the sharp cut edge with colorful washi tape or ribbon.',
            'Group together on your desk to organize pens, pencils, and scissors.',
          ],
          iconName: 'edit',
        ),
        const ReuseIdea(
          id: 'idea_planter',
          title: 'Self-Watering Planter',
          shortDescription: 'Use both halves of the bottle with a cotton string to auto-hydrate herbs.',
          category: 'Plastic',
          difficulty: 'Medium',
          timeRequired: '20 mins',
          materialsNeeded: [
            '1 Plastic Bottle',
            'Cotton String or Fabric Strip',
            'Scissors',
            'Soil & Herb Plant',
          ],
          steps: [
            'Cut the bottle in half horizontally.',
            'Invert the top cap section into the lower base section.',
            'Thread a thick cotton string through the cap hole down into the bottom water reservoir.',
            'Fill top cone with soil and plant; add water to bottom reservoir.',
          ],
          iconName: 'water_drop',
        ),
        const ReuseIdea(
          id: 'idea_bird_feeder',
          title: 'Bird Feeder',
          shortDescription: 'Insert wooden spoons through the bottle to create perches and seed tray.',
          category: 'Plastic',
          difficulty: 'Easy',
          timeRequired: '15 mins',
          materialsNeeded: [
            '1 Large Plastic Bottle',
            '2 Wooden Spoons',
            'Strong String/Wire for hanging',
            'Bird Seed',
          ],
          steps: [
            'Clean and thoroughly dry the bottle.',
            'Cut small opposing holes to push wooden spoons through as perches.',
            'Fill with bird seed so seeds trickle onto spoon bowl.',
            'Tie string around the bottle neck and hang outdoors.',
          ],
          iconName: 'flutter_dash',
        ),
      ],
    ),
    RecyclingItem(
      id: 'item_glass_jar',
      name: 'Glass Jar',
      category: 'Other',
      description: 'Preserve or food glass container suitable for storage or craft projects.',
      iconName: 'wine_bar',
      reuseIdeas: [
        const ReuseIdea(
          id: 'idea_candle_holder',
          title: 'Ambient Candle Holder',
          shortDescription: 'Wrap with twine or paint patterns to create cozy tea-light lanterns.',
          category: 'Other',
          difficulty: 'Easy',
          timeRequired: '10 mins',
          materialsNeeded: [
            '1 Clean Glass Jar',
            'Jute Twine',
            'Tea Light Candle',
          ],
          steps: [
            'Ensure the jar is completely clean and dry.',
            'Wrap jute twine securely around the neck or body.',
            'Insert LED or tea light candle inside for a warm glow.',
          ],
          iconName: 'lightbulb',
        ),
      ],
    ),
    RecyclingItem(
      id: 'item_cardboard_box',
      name: 'Cardboard Box',
      category: 'Paper',
      description:
          'Corrugated shipping or storage box made of recycled paper fibers.',
      iconName: 'inventory_2',
      reuseIdeas: [
        const ReuseIdea(
          id: 'idea_drawer_divider',
          title: 'Drawer Organizer',
          shortDescription:
              'Cut panels to create custom slots for clothes or desk drawers.',
          category: 'Paper',
          difficulty: 'Easy',
          timeRequired: '15 mins',
          materialsNeeded: ['Cardboard box', 'Ruler', 'Utility Knife/Scissors'],
          steps: [
            'Measure drawer dimensions.',
            'Cut cardboard strips to fit across drawer length and width.',
            'Slit interlocking notches so strips cross to form compartments.',
          ],
          iconName: 'dashboard',
        ),
      ],
    ),
    RecyclingItem(
      id: 'item_old_smartphone',
      name: 'Old Smartphone / E-Waste',
      category: 'E-Waste',
      description: 'Unused electronic mobile phone or gadget.',
      iconName: 'smartphone',
      reuseIdeas: [
        const ReuseIdea(
          id: 'idea_security_cam',
          title: 'Home Security Cam',
          shortDescription:
              'Repurpose an old functional phone as a Wi-Fi monitoring camera.',
          category: 'E-Waste',
          difficulty: 'Medium',
          timeRequired: '10 mins',
          materialsNeeded: [
            'Old Smartphone',
            'Wi-Fi Connection',
            'Phone Mount',
          ],
          steps: [
            'Factory reset old phone and connect to Wi-Fi.',
            'Download a security camera app (e.g. Alfred Camera).',
            'Mount phone facing desired doorway or yard angle.',
          ],
          iconName: 'videocam',
        ),
      ],
    ),
  ]);
}
