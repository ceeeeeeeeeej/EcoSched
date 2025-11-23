import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';

class ResidentLocationMapScreen extends StatefulWidget {
  final String? barangay;
  final String? purok;
  final String? currentLocation;

  const ResidentLocationMapScreen({
    super.key,
    this.barangay,
    this.purok,
    this.currentLocation,
  });

  @override
  State<ResidentLocationMapScreen> createState() =>
      _ResidentLocationMapScreenState();
}

class _ResidentLocationMapScreenState extends State<ResidentLocationMapScreen> {
  static const LatLng _fallbackCenter = LatLng(9.0721, 125.6083);
  static const Set<String> _supportedBarangays = {
    'victoria',
    'victoria, tago, surigao del sur',
    'dayo-an',
    'dayo-an, tago, surigao del sur',
    'dayo-ay',
    'dayo-ay, tago, surigao del sur',
  };
  static final List<_LatLngBounds> _serviceAreaBounds = [
    const _LatLngBounds(
      minLatitude: 9.0500,
      maxLatitude: 9.0950,
      minLongitude: 125.5850,
      maxLongitude: 125.6400,
    ), // Victoria core
    const _LatLngBounds(
      minLatitude: 9.0200,
      maxLatitude: 9.0800,
      minLongitude: 125.5600,
      maxLongitude: 125.6200,
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

  @override
  void initState() {
    super.initState();
    if (_isBarangaySupported) {
      _fetchCurrentLocation();
    } else {
      _locationError =
          'EcoSched is currently limited to Victoria and Dayo-an in Tago, Surigao del Sur.';
    }
  }

  Widget _buildUnsupportedBarangayCard(String barangayLabel) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              'Supported barangays:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Victoria, Tago, Surigao del Sur\n• Dayo-an, Tago, Surigao del Sur',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasManualDirections =>
      widget.currentLocation != null &&
      widget.currentLocation!.trim().isNotEmpty;

  bool get _isBarangaySupported {
    final barangay = widget.barangay?.trim().toLowerCase();
    if (barangay == null) return false;
    return _supportedBarangays.contains(barangay);
  }

  bool get _isDeveloperOverrideEnabled => kDebugMode;

  bool get _canContinue =>
      _isBarangaySupported && (_currentLatLng != null || _hasManualDirections);

  void _goToDashboard() {
    if (!_canContinue) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.residentDashboard,
      (route) => false,
    );
  }

  Future<void> _fetchCurrentLocation() async {
    if (!_isBarangaySupported) return;
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
      _developerBypassActive = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled on this device.';
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission was denied.';
          _isFetchingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission is permanently denied. Please enable it in system settings.';
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final detectedLatLng = LatLng(position.latitude, position.longitude);

      if (!_isWithinServiceArea(detectedLatLng)) {
        if (_isDeveloperOverrideEnabled &&
            _isWithinDeveloperSandbox(detectedLatLng)) {
          setState(() {
            _currentLatLng = detectedLatLng;
            _isFetchingLocation = false;
            _developerBypassActive = true;
            _locationError = null;
          });
          _animateToCurrentLocation();
          return;
        }

        setState(() {
          _currentLatLng = null;
          _isFetchingLocation = false;
          _developerBypassActive = false;
          _locationError =
              'Your detected location is currently outside EcoSched’s supported coverage (Victoria & Dayo-ay, Tago).';
        });
        return;
      }

      setState(() {
        _currentLatLng = detectedLatLng;
        _isFetchingLocation = false;
        _developerBypassActive = false;
      });

      _animateToCurrentLocation();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get your current location.';
        _isFetchingLocation = false;
        _developerBypassActive = false;
      });
    }
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
    final barangayLabel = widget.barangay ?? 'your barangay';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Location — $barangayLabel'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(barangayLabel),
                  const SizedBox(height: 16),
                  if (_isBarangaySupported) ...[
                    _buildCurrentLocationCard(),
                    const SizedBox(height: 16),
                    if (_hasManualDirections) ...[
                      const SizedBox(height: 16),
                      _buildLocationDetails(widget.currentLocation!.trim()),
                    ],
                  ] else ...[
                    _buildUnsupportedBarangayCard(barangayLabel),
                  ],
                ],
              ),
            ),
          ),
          _buildFooter(barangayLabel),
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
                        'Make sure the pin sits inside Victoria or Dayo-an.',
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
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textDark),
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
        : _currentLatLng != null
            ? 'GPS pin locked near ${_currentLatLng!.latitude.toStringAsFixed(4)}, '
                '${_currentLatLng!.longitude.toStringAsFixed(4)}'
            : _hasManualDirections
                ? 'Using your additional directions'
                : 'Waiting for an accurate location';

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
              if (_hasManualDirections)
                _buildStatusPill(
                  icon: Icons.edit_location_alt,
                  label: 'Manual directions added',
                  background: Colors.blueGrey.withOpacity(0.12),
                  foreground: Colors.blueGrey.shade700,
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
                          colorScheme.surfaceVariant,
                          colorScheme.surfaceVariant
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
