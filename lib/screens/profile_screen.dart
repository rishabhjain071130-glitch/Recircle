import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'rewards_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;

  const ProfileScreen({
    super.key,
    required this.appState,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileSheet() {
    final user = widget.appState.user;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.appState.updateUser(
                      user.copyWith(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        location: locationController.text.trim(),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.accentLightGreen,
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.subtitleGrey),
                      const SizedBox(width: 4),
                      Text(
                        user.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showEditProfileSheet,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Menu Options
            _buildProfileSection(
              title: 'Account Settings',
              items: [
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: '${user.email} • ${user.phone}',
                  onTap: _showEditProfileSheet,
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Pickup Addresses',
                  subtitle: user.location,
                  onTap: _showEditProfileSheet,
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  subtitle: 'Push & pickup updates enabled',
                  onTap: () {
                    _showInfoDialog(
                      'Notifications',
                      'Notification preferences will be saved once backend connection is configured.',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildProfileSection(
              title: 'Rewards & Activity',
              items: [
                _ProfileMenuItem(
                  icon: Icons.stars_outlined,
                  title: 'Rewards',
                  subtitle: '${widget.appState.impactStats.rewardPoints} points available',
                  iconColor: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RewardsScreen(appState: widget.appState),
                      ),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Activity History',
                  subtitle: 'View past reuses & pickups',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RewardsScreen(appState: widget.appState),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildProfileSection(
              title: 'Support & Legal',
              items: [
                _ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    _showInfoDialog(
                      'Help & Support',
                      'For questions regarding item recycling, DIY guides, or pickup schedules, contact support@recircle.app',
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'About ReCircle',
                  subtitle: 'v1.0.0 • Customer Mobile App',
                  onTap: () {
                    _showInfoDialog(
                      'About ReCircle',
                      'ReCircle is a Smart E-Waste & Plastic Recycling Management System built on the core principle: "Reuse First, Recycle When Needed."',
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    _showInfoDialog(
                      'Privacy Policy',
                      'ReCircle respects your privacy. Local user location is used strictly for organizing pickup collections.',
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    _showInfoDialog(
                      'Terms of Service',
                      'By using ReCircle, you agree to eco-friendly disposal guidelines and partner pickup terms.',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<_ProfileMenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.subtitleGrey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor ?? AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtitleGrey,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });
}
