import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/bin_service.dart';

class ResidentLocationMapScreen extends StatefulWidget {
  final String? barangay;
  final String? purok;

  const ResidentLocationMapScreen({
    super.key,
    this.barangay,
    this.purok,
  });

  @override
  State<ResidentLocationMapScreen> createState() =>
      _ResidentLocationMapScreenState();
}

class _ResidentLocationMapScreenState extends State<ResidentLocationMapScreen> {
  static const LatLng _fallbackCenter = LatLng(9.0336, 126.2094);
  static const Set<String> _supportedBarangays = {
    'victoria',
    'victoria, tago, surigao del sur',
    'dayo-an',
    'dayo-an, tago, surigao del sur',
    'dayo-ay, tago, surigao del sur',
  };
  static final List<_LatLngBounds> _serviceAreaBounds = [
    const _LatLngBounds(
      minLatitude: 9.0000,
      maxLatitude: 9.0700,
      minLongitude: 126.1800,
      maxLongitude: 126.2400,
    ), // Victoria core
    const _LatLngBounds(
      minLatitude: 8.9900,
      maxLatitude: 9.0500,
      minLongitude: 126.1500,
      maxLongitude: 126.2100,
    ), // Dayo-ay / Dayo-an stretch
  ];
  static final List<_LatLngBounds> _developerSandboxBounds = [
    const _LatLngBounds(
      minLatitude: 8.7400,
      maxLatitude: 8.7700,
      minLongitude: 126.2200,
      maxLongitude: 126.2500,
    ), // Hornasan, San Agustin, Surigao del Sur
  ];

  final MapController _mapController = MapController();

  LatLng? _currentLatLng;
  bool _isFetchingLocation = false;
  String? _locationError;
  bool _isMapReady = false;
  double _mapZoom = 17;
  bool _developerBypassActive = false;
  bool _hasCoverageError = false;
  bool _hasBarangayMismatchError = false;

  @override
  void initState() {
    super.initState();
    // Centering on barangay by default without waiting for GPS
    _centerOnSelection();

    Future.microtask(() {
      if (mounted) {
        final auth = context.read<AuthService>();
        final b = widget.barangay ?? auth.user?['barangay'];
        if (b != null) context.read<BinService>().loadBinsForArea(b);
      }
    });
  }

  Widget _buildUnsupportedBarangayCard(String barangayLabel) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.accentOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'EcoSched coverage is limited',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$barangayLabel is currently outside EcoSched’s supported areas. '
              'We are rolling out soon in more barangays within Tago, Surigao del Sur.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? theme.colorScheme.onSurface.withOpacity(0.8)
                    : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Supported barangays:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkTheme
                    ? theme.colorScheme.onSurface
                    : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Victoria, Tago, Surigao del Sur\n• Dayo-an, Tago, Surigao del Sur',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? theme.colorScheme.onSurface.withOpacity(0.8)
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isBarangaySupported {
    final barangay = widget.barangay?.trim().toLowerCase();
    if (barangay == null) return false;
    return _supportedBarangays.contains(barangay);
  }

  bool get _isDeveloperOverrideEnabled => kDebugMode;

  bool get _hasCriticalLocationError =>
      _hasCoverageError || _hasBarangayMismatchError;

  bool get _canContinue => _isBarangaySupported && !_hasCriticalLocationError;

  String _mapBarangayToServiceArea(String? barangay) {
    final value = (barangay ?? '').trim().toLowerCase();
    if (value.contains('victoria')) {
      return 'victoria';
    }
    if (value.contains('dayo-an') || value.contains('dayo-ay')) {
      return 'dayo-an';
    }
    return 'victoria';
  }

  void _goToDashboard() {
    if (!_canContinue) return;
    final auth = context.read<AuthService>();
    final pickupService = context.read<PickupService>();

    final barangay = widget.barangay ?? '';
    final purok = widget.purok ?? 'Purok 1';

    auth.setResidentLocation(
      barangay: barangay,
      purok: purok,
    );

    final serviceArea = _mapBarangayToServiceArea(barangay);
    pickupService.loadSchedulesForServiceArea(serviceArea);

    // NotificationService.subscribeToServiceAreaTopic(serviceArea,
    //     userId: auth.residentId);

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.residentDashboard,
      (route) => false,
    );
  }

  void _centerOnSelection() {
    final b = widget.barangay?.toLowerCase() ?? '';
    if (b.contains('victoria')) {
      _currentLatLng = const LatLng(9.0783, 126.1987);
    } else if (b.contains('dayo-an')) {
      _currentLatLng = const LatLng(9.0821, 126.2010);
    } else {
      _currentLatLng = _fallbackCenter;
    }
    if (_isMapReady) {
      _mapController.move(_currentLatLng!, _mapZoom);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    // Location tracking removed to ensure zero GPS dependency.
    _centerOnSelection();
  }

  void _handleMapReady() {
    setState(() {
      _isMapReady = true;
    });
    _animateToCurrentLocation(force: true);
  }

  void _handleMapEvent(MapEvent event) {
    if (!mounted) return;
    setState(() {
      _mapZoom = event.camera.zoom;
    });
  }

  void _animateToCurrentLocation({bool force = false}) {
    if (_currentLatLng == null || !_isMapReady) return;
    if (!force && (_mapController.camera.center == _currentLatLng)) return;
    _mapController.move(_currentLatLng!, _mapZoom);
  }

  void _changeZoom(double delta) {
    final newZoom = (_mapZoom + delta).clamp(3.0, 19.0);
    setState(() {
      _mapZoom = newZoom;
    });
    if (_isMapReady) {
      _mapController.move(_mapController.camera.center, newZoom);
    }
  }

  void _recenterMap() {
    if (_currentLatLng != null) {
      _animateToCurrentLocation(force: true);
    } else {
      _fetchCurrentLocation();
    }
  }

  bool _isWithinServiceArea(LatLng point) {
    for (final bounds in _serviceAreaBounds) {
      if (bounds.contains(point)) {
        return true;
      }
    }
    return false;
  }

  bool _isWithinSelectedBarangay(LatLng point) {
    final barangay = (widget.barangay ?? '').trim().toLowerCase();

    if (barangay.contains('victoria')) {
      if (_serviceAreaBounds.isNotEmpty) {
        final victoriaBounds = _serviceAreaBounds[0];
        return victoriaBounds.contains(point);
      }
      return false;
    }

    if (barangay.contains('dayo-an') || barangay.contains('dayo-ay')) {
      if (_serviceAreaBounds.length > 1) {
        final dayoanBounds = _serviceAreaBounds[1];
        return dayoanBounds.contains(point);
      }
      return false;
    }
    return _isWithinServiceArea(point);
  }

  bool _isWithinDeveloperSandbox(LatLng point) {
    for (final bounds in _developerSandboxBounds) {
      if (bounds.contains(point)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final binService = context.watch<BinService>();
    final bins = binService.bins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Location'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? _fallbackCenter,
              initialZoom: _mapZoom,
              onMapReady: _handleMapReady,
              onMapEvent: _handleMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.ecosched.app',
              ),
              MarkerLayer(
                markers: [
                  ...bins.map((bin) {
                    final dynLat = bin['location_lat'] ?? bin['gps_lat'];
                    final dynLng = bin['location_lng'] ?? bin['gps_lng'];
                    if (dynLat == null || dynLng == null) return null;

                    final lat = (dynLat is num)
                        ? dynLat.toDouble()
                        : double.tryParse(dynLat.toString()) ?? 0.0;
                    final lng = (dynLng is num)
                        ? dynLng.toDouble()
                        : double.tryParse(dynLng.toString()) ?? 0.0;

                    if (lat == 0.0 && lng == 0.0) return null;

                    final fillLevel = bin['fill_level'] ?? 0;
                    final isFull = fillLevel >= 80;

                    return Marker(
                      width: 180,
                      height: 90,
                      point: LatLng(lat, lng),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? AppTheme.accentOrange
                                  : AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Bin location is here in ${bin['address'] ?? bin['location'] ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const CustomPaint(
                            size: Size(20, 10),
                            painter: _TrianglePainter(color: Colors.white),
                          ),
                          Icon(
                            isFull ? Icons.warning_rounded : Icons.delete,
                            color: isFull
                                ? AppTheme.accentOrange
                                : AppTheme.primaryGreen,
                            size: 32,
                          ),
                        ],
                      ),
                    );
                  }).whereType<Marker>(),
                  if (_currentLatLng != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _currentLatLng!,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Zoom & recenter controls
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              children: [
                _MapIconButton(
                  icon: Icons.zoom_in,
                  onPressed: () => _changeZoom(0.5),
                ),
                const SizedBox(height: 8),
                _MapIconButton(
                  icon: Icons.zoom_out,
                  onPressed: () => _changeZoom(-0.5),
                ),
                const SizedBox(height: 8),
                _MapIconButton(
                  icon: Icons.my_location,
                  onPressed: _recenterMap,
                ),
              ],
            ),
          ),
          if (_isFetchingLocation)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildIntroCard(String barangayLabel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.map_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Barangay: $barangayLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'EcoSched needs your approximate location to tailor reminders and collection routes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusPill(
                  icon: Icons.verified_user,
                  label: 'Secure & private',
                  background: colorScheme.primary.withOpacity(0.12),
                  foreground: colorScheme.primary,
                ),
                _buildStatusPill(
                  icon: Icons.notifications_active,
                  label: 'Personalized reminders',
                  background: colorScheme.secondary.withOpacity(0.12),
                  foreground: colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Widget statusBadge;
    if (_isFetchingLocation) {
      statusBadge = _buildStatusPill(
        icon: Icons.sync,
        label: 'Locating…',
        background: colorScheme.primary.withOpacity(0.12),
        foreground: colorScheme.primary,
      );
    } else if (_currentLatLng != null) {
      statusBadge = _buildStatusPill(
        icon: Icons.verified,
        label: 'Pin locked',
        background: colorScheme.primary.withOpacity(0.12),
        foreground: colorScheme.primary,
      );
    } else if (_locationError != null) {
      statusBadge = _buildStatusPill(
        icon: Icons.warning_amber_rounded,
        label: 'Action needed',
        background: AppTheme.accentOrange.withOpacity(0.14),
        foreground: AppTheme.accentOrange,
      );
    } else {
      statusBadge = _buildStatusPill(
        icon: Icons.touch_app,
        label: 'Tap to detect',
        background: AppTheme.textLight.withOpacity(0.15),
        foreground: AppTheme.textDark,
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2 of 2 • Confirm your pickup pin',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.my_location, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Make sure the pin sits inside Victoria, Dayo-an, or Mahayag.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: statusBadge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            if (_isFetchingLocation) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fetching your current location... This may take a few seconds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_locationError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.accentOrange.withOpacity(0.12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.accentOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _fetchCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Try again'),
                ),
              ),
            ] else if (_currentLatLng != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLatLng ?? _fallbackCenter,
                          initialZoom: _mapZoom,
                          onMapReady: _handleMapReady,
                          onMapEvent: _handleMapEvent,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecosched.app',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_currentLatLng != null)
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: _currentLatLng!,
                                  child: const Icon(
                                    Icons.place,
                                    color: AppTheme.primaryGreen,
                                    size: 36,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Column(
                          children: [
                            _MapIconButton(
                              icon: Icons.zoom_in,
                              onPressed: () => _changeZoom(0.5),
                            ),
                            const SizedBox(height: 8),
                            _MapIconButton(
                              icon: Icons.zoom_out,
                              onPressed: () => _changeZoom(-0.5),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _MapIconButton(
                          icon: Icons.my_location,
                          onPressed: _recenterMap,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 72,
                        child: _MapIconButton(
                          icon: Icons.layers,
                          onPressed: _isFetchingLocation
                              ? null
                              : _fetchCurrentLocation,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.4)
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lat ${_currentLatLng!.latitude.toStringAsFixed(5)} · Lng ${_currentLatLng!.longitude.toStringAsFixed(5)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              _buildMiniDivider(),
                              const SizedBox(width: 8),
                              const Icon(Icons.security,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Safe zone',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lat: ${_currentLatLng!.latitude.toStringAsFixed(5)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        _buildStatusPill(
                          icon: Icons.shield_moon,
                          label: 'Within service area',
                          background: colorScheme.primary.withOpacity(0.12),
                          foreground: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lng: ${_currentLatLng!.longitude.toStringAsFixed(5)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_developerBypassActive)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.accentOrange.withOpacity(0.12),
                      border: Border.all(
                        color: AppTheme.accentOrange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering,
                            color: AppTheme.accentOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Developer override active (Hornasan). This location is outside production coverage.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.4),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pin not detected yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the button below so EcoSched can verify that you are within the supported barangays.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check,
                            size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Needed to unlock reminders and pickup schedules.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fetchCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Detect location'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetails(String location) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Directions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? theme.colorScheme.onSurface
                    : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(String barangayLabel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationStatus = !_isBarangaySupported
        ? 'Outside EcoSched coverage. Currently limited to Victoria and Dayo-an (Tago, Surigao del Sur).'
        : 'Map center loaded for $barangayLabel.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            top: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You are in $barangayLabel${_isBarangaySupported ? '' : ' (not yet supported)'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locationStatus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_currentLatLng != null)
                _buildStatusPill(
                  icon: Icons.place,
                  label: 'GPS pin ready',
                  background: AppTheme.primaryGreen.withOpacity(0.12),
                  foreground: AppTheme.primaryGreen,
                ),
              _buildStatusPill(
                icon: Icons.map,
                label: 'Coverage: Victoria & Dayo-an',
                background: AppTheme.textLight.withOpacity(0.15),
                foreground: AppTheme.textDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _canContinue
                    ? LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest,
                          colorScheme.surfaceContainerHighest
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: _canContinue ? _goToDashboard : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _canContinue
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline,
                      color: _canContinue
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue to EcoSched',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: _canContinue
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _canContinue
                              ? 'Your pickup point looks good'
                              : 'Allow location access to unlock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _canContinue
                                ? colorScheme.onPrimary.withOpacity(0.8)
                                : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_canContinue)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Allow location access or provide directions to continue.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _LatLngBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  const _LatLngBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  bool contains(LatLng point) {
    return point.latitude >= minLatitude &&
        point.latitude <= maxLatitude &&
        point.longitude >= minLongitude &&
        point.longitude <= maxLongitude;
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _MapIconButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color:
                onPressed == null ? AppTheme.textLight : AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
