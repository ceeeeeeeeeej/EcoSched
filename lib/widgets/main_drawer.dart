import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/routes/app_router.dart';
import '../core/services/auth_service.dart';
import '../core/services/pickup_service.dart';
import '../core/providers/app_state_provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final String displayName = (auth.user?['displayName'] as String?) ?? 'User';
    final String email = (auth.user?['email'] as String?) ?? '';
    final bool isCollector = auth.isCollector();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(displayName, email),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.residentDashboard);
                      },
                    ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Schedule Pickup'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.schedulePickup);
                      },
                    ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: const Text('Collection History'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.residentCollectionHistory);
                      },
                    ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.compost_outlined),
                      title: const Text('Nearest Compost Pits'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.compostPitFinder);
                      },
                    ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.feedback_outlined),
                      title: const Text('Feedback'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.residentFeedback);
                      },
                    ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.tips_and_updates_outlined),
                      title: const Text('Eco Tips & Guides'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.ecoTips);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.profile);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                  ),
                  if (!isCollector)
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.residentNotifications);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Feedback'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Help & Feedback'),
                          content: const Text(
                              'Tell us how we can improve EcoSched!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showAboutDialog(
                        context: context,
                        applicationName: 'EcoSched',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log out',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                // 1. Capture what we need before any async/pop operations
                final navigator = Navigator.of(context);
                final auth = context.read<AuthService>();
                final pickup = context.read<PickupService>();
                final appState = context.read<AppStateProvider>();

                // 2. Perform UI pop and state resets
                navigator.pop();
                pickup.reset();
                appState.reset();

                // 3. Perform sign out
                await auth.signOut();

                // 4. Navigate using the captured navigator
                navigator.pushNamedAndRemoveUntil(
                    AppRoutes.roleSelection, (route) => false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName, String email) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppTheme.primaryGradient),
      ),
      accountName: Text(displayName),
      accountEmail: Text(email),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E',
          style: const TextStyle(
              fontSize: 24, color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
