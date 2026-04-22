import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/localization/localization.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/mood_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  String? _appliedUserId;
  Future<void>? _syncFuture;

  void _ensureUserSynced(String? userId) {
    if (_appliedUserId == userId) return;
    _syncFuture ??= _syncForUser(userId);
  }

  Future<void> _syncForUser(String? userId) async {
    _appliedUserId = userId;
    final moodViewModel = context.read<MoodViewModel>();
    final settingsViewModel = context.read<SettingsViewModel>();
    await moodViewModel.setCurrentUser(userId);
    await settingsViewModel.setCurrentUser(userId);
    if (mounted) {
      setState(() {
        _syncFuture = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        _ensureUserSynced(user?.uid);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_syncFuture != null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return AppLoc(
            lang: 'en',
            child: Theme(
              data: ThemeData(
                colorSchemeSeed: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              child: const AuthScreen(),
            ),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
