import 'package:flutter/material.dart';
import '../models/pickup.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PickupBookingScreen extends StatefulWidget {
  final AppState appState;
  final String? initialItemName;
  final String? initialCategory;

  const PickupBookingScreen({
    super.key,
    required this.appState,
    this.initialItemName,
    this.initialCategory,
  });

  @override
  State<PickupBookingScreen> createState() => _PickupBookingScreenState();
}

class _PickupBookingScreenState extends State<PickupBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemController;
  late TextEditingController _quantityController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  String _selectedCategory = 'Plastic';
  String _selectedDate = 'Tomorrow';
  String _selectedTime = '10:00 AM - 12:00 PM';

  final List<String> _categories = [
    'Plastic',
    'E-Waste',
    'Paper',
    'Metal',
    'Other',
  ];

  final List<String> _dates = [
    'Today',
    'Tomorrow',
    'Day After Tomorrow',
  ];

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.initialItemName ?? '');
    _quantityController = TextEditingController(text: '1.5 kg');
    _addressController = TextEditingController(text: widget.appState.user.location);
    _notesController = TextEditingController();

    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitPickup() {
    if (_formKey.currentState!.validate()) {
      final newPickup = Pickup(
        id: 'RC${1000 + widget.appState.pickups.length + 1}',
        itemName: _itemController.text.trim(),
        category: _selectedCategory,
        quantity: _quantityController.text.trim(),
        pickupAddress: _addressController.text.trim(),
        preferredDate: _selectedDate,
        preferredTime: _selectedTime,
        status: PickupStatus.booked,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      widget.appState.bookPickup(newPickup);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primaryGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pickup Request Created',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your pickup request has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.subtitleGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reward subject to applicable recycling rules and verification.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return from booking screen
                  },
                  child: const Text('Track My Pickup'),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Recycling Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule a Pickup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Our partner will collect your recyclable items right from your doorstep.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtitleGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Step 1: Item Name
              _buildStepHeader('1', 'Select Item Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemController,
                decoration: _inputDecoration('e.g. Plastic Water Bottles, Old Electronics'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Step 2: Category
              _buildStepHeader('2', 'Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.accentLightGreen,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.darkText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Step 3: Quantity
              _buildStepHeader('3', 'Estimated Quantity'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: _inputDecoration('e.g. 2.5 kg or 5 pieces'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Step 4: Pickup Address
              _buildStepHeader('4', 'Pickup Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Enter your full pickup address'),
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Step 5: Preferred Date
              _buildStepHeader('5', 'Preferred Date'),
              const SizedBox(height: 8),
              Row(
                children: _dates.map((date) {
                  final isSelected = date == _selectedDate;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? AppTheme.accentLightGreen : Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.darkText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Step 6: Preferred Time
              _buildStepHeader('6', 'Preferred Time Slot'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: _inputDecoration('Select Time'),
                items: _timeSlots.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTime = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Additional notes
              const Text(
                'Notes / Instructions (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('e.g. Ring doorbell, leave at gate'),
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitPickup,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm Pickup'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String stepNumber, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
    );
  }
}
