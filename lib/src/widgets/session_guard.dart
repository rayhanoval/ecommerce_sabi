import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/auth_repository.dart';
import '../pages/login_page.dart';

class SessionGuard extends ConsumerStatefulWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  ConsumerState<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends ConsumerState<SessionGuard> {
  final _storage = const FlutterSecureStorage();
  RealtimeChannel? _subscription;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _startListening();
    // Listen to auth state changes to start/stop listening
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _startListening();
        NotificationService().uploadToken(null);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _stopListening();
      }
    });
  }

  void _stopListening() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
      _subscription = null;
    }
  }

  Future<void> _startListening() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _stopListening();

    _subscription = Supabase.instance.client
        .channel('public:users')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: user.id,
            ),
            callback: (payload) async {
              debugPrint(
                  'SessionGuard: Update received! Payload: ${payload.toString()}');
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) {
                debugPrint('SessionGuard: newRecord is empty');
                return;
              }

              final serverSessionId = newRecord['active_session_id'];
              final localSessionId = await _storage.read(key: 'session_id');

              debugPrint('SessionGuard: Server Session ID: $serverSessionId');
              debugPrint('SessionGuard: Local Session ID: $localSessionId');

              if (serverSessionId != null &&
                  localSessionId != null &&
                  serverSessionId != localSessionId) {
                debugPrint(
                    'SessionGuard: Session mismatch! Triggering logout dialog.');
                if (mounted && !_isDialogShowing) {
                  _showSessionExpiredDialog();
                }
              } else {
                debugPrint('SessionGuard: Session IDs match or valid.');
              }
            })
        .subscribe((status, error) {
      debugPrint('SessionGuard: Subscription Status: $status');
      if (error != null) debugPrint('SessionGuard: Subscription Error: $error');
    });
  }

  void _showSessionExpiredDialog() {
    setState(() => _isDialogShowing = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
            'You have logged in on another device. You have been logged out from this device.'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                // Dismiss dialog
                Navigator.of(context).pop();
                setState(() => _isDialogShowing = false);

                // Navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
