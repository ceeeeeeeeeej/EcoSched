import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../core/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final String displayName = (auth.user?['displayName'] as String?) ?? 'EcoSched User';
    final String email = (auth.user?['email'] as String?) ?? 'user@example.com';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacing8), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 24),
              GlassmorphicContainer(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.spacing8), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _kv(context, 'Role', auth.isCollector() ? 'Collector' : 'Resident'),
                    const SizedBox(height: 8),
                    _kv(context, 'Email verified', (auth.user?['emailVerified'] == true) ? 'Yes' : 'No'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}


