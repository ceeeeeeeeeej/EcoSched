import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class BinService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _bins = [];
  StreamSubscription<List<Map<String, dynamic>>>? _binSubscription;
  String? _currentArea;

  List<Map<String, dynamic>> get bins => List.unmodifiable(_bins);

  /// Load and stream bins for a specific service area (barangay)
  Future<void> loadBinsForArea(String area) async {
    final normalizedArea = area.toLowerCase().trim();
    if (_currentArea == normalizedArea && _binSubscription != null) return;

    await _binSubscription?.cancel();
    _currentArea = normalizedArea;

    if (kDebugMode) print('📡 BinService: Starting stream for $normalizedArea');

    _binSubscription = _supabase
        .from(SupabaseConfig.binsTable)
        .stream(primaryKey: ['id'])
        .eq('zone', normalizedArea)
        .listen(
          (data) {
            _bins = List<Map<String, dynamic>>.from(data);
            // Sort by fill level descending so full bins are prominent
            _bins.sort((a, b) =>
                (b['fill_level'] ?? 0).compareTo(a['fill_level'] ?? 0));
            notifyListeners();
            if (kDebugMode) {
              print('📡 BinService: Received ${data.length} bins');
            }
          },
          onError: (error) {
            if (kDebugMode) print('❌ BinService Error: $error');
          },
        );
  }

  void reset() {
    _binSubscription?.cancel();
    _binSubscription = null;
    _bins.clear();
    _currentArea = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _binSubscription?.cancel();
    super.dispose();
  }
}
