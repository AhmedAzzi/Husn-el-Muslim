import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/mosque_api.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/core/utils/l10n_ext.dart';

/// Supported countries for Mawaqit API mapping
class CountryInfo {
  final String code;
  final String name;
  final String flag;
  final LatLng center;
  final double defaultZoom;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.center,
    this.defaultZoom = 6.0,
  });
}

const List<CountryInfo> kSupportedCountries = [
  CountryInfo(code: 'DZ', name: 'الجزائر', flag: '🇩🇿', center: LatLng(36.75, 3.05), defaultZoom: 6),
  CountryInfo(code: 'SA', name: 'المملكة العربية السعودية', flag: '🇸🇦', center: LatLng(24.71, 46.67), defaultZoom: 6),
  CountryInfo(code: 'EG', name: 'مصر', flag: '🇪🇬', center: LatLng(30.04, 31.23), defaultZoom: 6),
  CountryInfo(code: 'MA', name: 'المغرب', flag: '🇲🇦', center: LatLng(33.57, -7.58), defaultZoom: 6),
  CountryInfo(code: 'TN', name: 'تونس', flag: '🇹🇳', center: LatLng(36.80, 10.18), defaultZoom: 7),
  CountryInfo(code: 'AE', name: 'الإمارات العربية المتحدة', flag: '🇦🇪', center: LatLng(25.20, 55.27), defaultZoom: 7),
  CountryInfo(code: 'FR', name: 'فرنسا', flag: '🇫🇷', center: LatLng(48.85, 2.35), defaultZoom: 6),
  CountryInfo(code: 'GB', name: 'المملكة المتحدة', flag: '🇬🇧', center: LatLng(51.50, -0.12), defaultZoom: 6),
  CountryInfo(code: 'TR', name: 'تركيا', flag: '🇹🇷', center: LatLng(39.93, 32.85), defaultZoom: 6),
  CountryInfo(code: 'DE', name: 'ألمانيا', flag: '🇩🇪', center: LatLng(52.52, 13.40), defaultZoom: 6),
  CountryInfo(code: 'CA', name: 'كندا', flag: '🇨🇦', center: LatLng(45.42, -75.69), defaultZoom: 5),
  CountryInfo(code: 'US', name: 'الولايات المتحدة', flag: '🇺🇸', center: LatLng(38.90, -77.03), defaultZoom: 5),
  CountryInfo(code: 'ES', name: 'إسبانيا', flag: '🇪🇸', center: LatLng(40.41, -3.70), defaultZoom: 6),
  CountryInfo(code: 'BE', name: 'بلجيكا', flag: '🇧🇪', center: LatLng(50.85, 4.35), defaultZoom: 8),
  CountryInfo(code: 'IT', name: 'إيطاليا', flag: '🇮🇹', center: LatLng(41.90, 12.49), defaultZoom: 6),
];

class MosqueMapScreen extends StatefulWidget {
  final String countryCode;

  const MosqueMapScreen({super.key, this.countryCode = 'DZ'});

  @override
  State<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends State<MosqueMapScreen> {
  final MawaqitApi _api = MawaqitApi();
  final MapController _mapController = MapController();
  final PrayerTimesLogic _prayerLogic = PrayerTimesLogic();

  late String _selectedCountryCode;
  bool _loading = true;
  bool _offline = false;
  String? _error;

  List<MosquePoint> _allMosques = [];
  List<MosquePoint> _filteredMosques = [];
  List<Marker> _markers = [];

  MosquePoint? _selectedMosque;
  MosqueSchedule? _selectedSchedule;
  bool _scheduleLoading = false;
  String? _scheduleError;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // View mode: false = map, true = list
  bool _showListView = false;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.countryCode;
    _searchController.addListener(_onSearchChanged);
    // _loadMosques reads localizations (inherited widget): it must run
    // after the first frame, never synchronously inside initState —
    // otherwise the framework throws and the map screen dies on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMosques();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  CountryInfo get _currentCountry => kSupportedCountries.firstWhere(
        (c) => c.code.toUpperCase() == _selectedCountryCode.toUpperCase(),
        orElse: () => kSupportedCountries.first,
      );

  Future<void> _loadMosques({bool forceRefresh = false}) async {
    final loc = context.loc;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final mosques = await _api.mosquesByCountry(_selectedCountryCode,
          forceRefresh: forceRefresh);
      if (!mounted) return;
      final valid = mosques
          .where((m) => m.latitude != 0 || m.longitude != 0)
          .toList();

      setState(() {
        _allMosques = valid;
        _filterMosques();
        _loading = false;
        _offline = false;
      });

      // Move map to country center or user location
      final c = _currentCountry;
      _mapController.move(c.center, c.defaultZoom);
    } on http.ClientException {
      // Network-level error (DNS, connection refused, timeout)
      final cached = await OfflineCache.getMosques(_selectedCountryCode);
      if (!mounted) return;
      if (cached != null) {
        final valid = cached
            .where((m) => m.latitude != 0 || m.longitude != 0)
            .toList();
        setState(() {
          _allMosques = valid;
          _filterMosques();
          _loading = false;
          _offline = true;
          _error = null;
        });
        return;
      }
      setState(() {
        _error = loc.mmErrorNetwork;
        _loading = false;
      });
    } on FormatException {
      // JSON parsing error - likely API format changed
      final cached = await OfflineCache.getMosques(_selectedCountryCode);
      if (!mounted) return;
      if (cached != null) {
        final valid = cached
            .where((m) => m.latitude != 0 || m.longitude != 0)
            .toList();
        setState(() {
          _allMosques = valid;
          _filterMosques();
          _loading = false;
          _offline = true;
          _error = null;
        });
        return;
      }
      setState(() {
        _error = loc.mmErrorParsing;
        _loading = false;
      });
    } catch (e) {
      // Other errors (including HTTP status errors thrown by API)
      final cached = await OfflineCache.getMosques(_selectedCountryCode);
      if (!mounted) return;
      if (cached != null) {
        final valid = cached
            .where((m) => m.latitude != 0 || m.longitude != 0)
            .toList();
        setState(() {
          _allMosques = valid;
          _filterMosques();
          _loading = false;
          _offline = true;
          _error = null;
        });
        return;
      }
      String message;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        message = loc.mmErrorNotFound;
      } else if (errorStr.contains('500') || errorStr.contains('server error')) {
        message = loc.mmErrorServer;
      } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        message = loc.mmErrorTimeout;
      } else {
        message = loc.mmErrorGeneral;
      }
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() => _filterMosques());
  }

  void _filterMosques() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredMosques = List.from(_allMosques);
    } else {
      _filteredMosques = _allMosques.where((m) {
        final matchName = m.name.toLowerCase().contains(query);
        final matchCity = m.city.toLowerCase().contains(query);
        final matchAddress = (m.address ?? '').toLowerCase().contains(query);
        return matchName || matchCity || matchAddress;
      }).toList();
    }
    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    final activeSlug = _prayerLogic.selectedMosque?.slug;
    _markers = _filteredMosques.map((m) {
      final isActive = m.slug == activeSlug;
      return _buildMarker(m, isActive: isActive);
    }).toList();
  }

  Marker _buildMarker(MosquePoint m, {bool isActive = false}) {
    return Marker(
      point: LatLng(m.latitude, m.longitude),
      width: isActive ? 48 : 38,
      height: isActive ? 56 : 46,
      child: GestureDetector(
        onTap: () => _selectMosque(m),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Marker Pin Background
            Container(
              width: isActive ? 44 : 36,
              height: isActive ? 44 : 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFFFFB300), const Color(0xFFFF6F00)]
                      : [const Color(0xFF693B42), const Color(0xFFD64463)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Colors.amber : const Color(0xFF693B42))
                        .withValues(alpha: 0.4),
                    blurRadius: isActive ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: isActive ? 2.5 : 1.5,
                ),
              ),
              child: Icon(
                isActive ? Icons.stars_rounded : Icons.mosque_rounded,
                color: Colors.white,
                size: isActive ? 24 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMosque(MosquePoint m, {bool forceRefresh = false}) async {
    final loc = context.loc;
    setState(() {
      _selectedMosque = m;
      _selectedSchedule = null;
      _scheduleError = null;
      _scheduleLoading = true;
    });

    _mapController.move(LatLng(m.latitude, m.longitude), 15);

    try {
      final s = await _api.scheduleBySlug(m.slug, forceRefresh: forceRefresh);
      if (!mounted || _selectedMosque?.slug != m.slug) return;
      setState(() {
        _selectedSchedule = s;
        _scheduleLoading = false;
        _offline = false;
      });
    } on http.ClientException {
      final cached = await OfflineCache.getSchedule(m.slug);
      if (!mounted || _selectedMosque?.slug != m.slug) return;
      if (cached != null) {
        setState(() {
          _selectedSchedule = cached;
          _scheduleLoading = false;
          _offline = true;
        });
        return;
      }
      setState(() {
        _scheduleError = loc.mmScheduleErrorNetwork;
        _scheduleLoading = false;
      });
    } on FormatException {
      final cached = await OfflineCache.getSchedule(m.slug);
      if (!mounted || _selectedMosque?.slug != m.slug) return;
      if (cached != null) {
        setState(() {
          _selectedSchedule = cached;
          _scheduleLoading = false;
          _offline = true;
        });
        return;
      }
      setState(() {
        _scheduleError = loc.mmScheduleErrorParsing;
        _scheduleLoading = false;
      });
    } catch (e) {
      final cached = await OfflineCache.getSchedule(m.slug);
      if (!mounted || _selectedMosque?.slug != m.slug) return;
      if (cached != null) {
        setState(() {
          _selectedSchedule = cached;
          _scheduleLoading = false;
          _offline = true;
        });
        return;
      }
      String message;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        message = loc.mmScheduleErrorNotFound;
      } else if (errorStr.contains('500') || errorStr.contains('server error')) {
        message = loc.mmScheduleErrorServer;
      } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        message = loc.mmScheduleErrorTimeout;
      } else {
        message = loc.mmScheduleErrorGeneral;
      }
      setState(() {
        _scheduleError = message;
        _scheduleLoading = false;
      });
    }
  }

  double? _calculateDistance(MosquePoint m) {
    final pos = _prayerLogic.currentPosition;
    if (pos == null) return null;
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((m.latitude - pos.latitude) * p) / 2 +
        cos(pos.latitude * p) *
            cos(m.latitude * p) *
            (1 - cos((m.longitude - pos.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _centerOnUserLocation() {
    final pos = _prayerLogic.currentPosition;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } else {
      _prayerLogic.ensureDataLoaded(force: true).then((_) {
        if (_prayerLogic.currentPosition != null) {
          _mapController.move(
              LatLng(_prayerLogic.currentPosition!.latitude,
                  _prayerLogic.currentPosition!.longitude),
              14);
        }
      });
    }
  }

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF23232E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public_rounded, color: Color(0xFFD64463)),
                  const SizedBox(width: 10),
                  Text(
                    context.loc.mmCountryPickerTitle,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kSupportedCountries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final country = kSupportedCountries[index];
                    final isSelected =
                        country.code.toUpperCase() == _selectedCountryCode.toUpperCase();
                    return ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFD64463)
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFFD64463))
                          : null,
                      onTap: () {
                        Get.back();
                        setState(() {
                          _selectedCountryCode = country.code;
                        });
                        _loadMosques();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: theme.appBarTheme.foregroundColor),
              onPressed: () => Get.back(),
            ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Amiri', fontSize: 18),
                    decoration: InputDecoration(
                      hintText: context.loc.mmSearchHint,
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'Amiri'),
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    context.loc.mmTitle,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: theme.appBarTheme.foregroundColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            actions: [
              IconButton(
                tooltip: _isSearching ? context.loc.mmCloseSearch : context.loc.mmSearch,
                icon: Icon(_isSearching ? Icons.close : Icons.search_rounded,
                    color: theme.appBarTheme.foregroundColor),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchController.clear();
                      _isSearching = false;
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              IconButton(
                tooltip: _showListView ? context.loc.mmShowMap : context.loc.mmShowList,
                icon: Icon(_showListView
                        ? Icons.map_rounded
                        : Icons.list_rounded,
                    color: theme.appBarTheme.foregroundColor),
                onPressed: () {
                  setState(() => _showListView = !_showListView);
                },
              ),
              IconButton(
                tooltip: context.loc.mmChangeCountry,
                icon: Text(_currentCountry.flag, style: const TextStyle(fontSize: 20)),
                onPressed: _showCountryPicker,
              ),
              IconButton(
                tooltip: context.loc.ctRefresh,
                onPressed: _loading ? null : () => _loadMosques(forceRefresh: true),
                icon: Icon(Icons.refresh_rounded,
                    color: theme.appBarTheme.foregroundColor),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(appBarBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              _showListView ? _buildListView() : _buildMap(),
              // Top Status/Filter Bar
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    // Country Chip
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF2C2C35)
                                  : Colors.white)
                              .withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_currentCountry.flag,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              _currentCountry.name,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Mosque Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFF2C2C35)
                                : Colors.white)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mosque_rounded,
                              size: 16, color: Color(0xFFD64463)),
                          const SizedBox(width: 6),
                          Text(
                            context.loc.mmMosqueCount(_filteredMosques.length),
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Offline Warning Banner
              if (_offline)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.mmOfflineBanner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Amiri',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_loading)
                Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD64463)),
                  ),
                ),

              if (_error != null)
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD64463),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _loadMosques(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.loc.mmRetry,
                                style: const TextStyle(fontFamily: 'Amiri')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // "Locate Me" Floating Button (map view only)
              if (!_showListView)
                Positioned(
                  bottom: _selectedMosque != null ? 300 : 24,
                  left: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'map_locate_me',
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C35)
                        : Colors.white,
                    foregroundColor: const Color(0xFFD64463),
                    elevation: 4,
                    onPressed: _centerOnUserLocation,
                    tooltip: context.loc.mmLocateMe,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
            ],
          ),
          bottomSheet: _selectedMosque != null ? _buildBottomSheet() : null,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCountry.center,
        initialZoom: _currentCountry.defaultZoom,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ahmed.hisnelmuslim',
          maxNativeZoom: 18,
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 65,
            markers: _markers,
            size: const Size(46, 46),
            centerMarkerOnClick: true,
            zoomToBoundsOnClick: true,
            disableClusteringAtZoom: 17,
            builder: (context, markers) => Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF693B42), Color(0xFFD64463)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD64463).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  markers.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// List view of all (filtered) mosques, shown instead of the map.
  Widget _buildListView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mosques = _filteredMosques;

    if (mosques.isEmpty) {
      return Center(
        child: Text(
          _allMosques.isEmpty
              ? context.loc.mmEmptyNoMosques
              : context.loc.mmEmptyNoResults,
          style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.grey.shade600),
        ),
      );
    }

    return SafeArea(
      child: Container(
        color: isDark ? const Color(0xFF1A1A22) : const Color(0xFFF7F2EF),
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 70),
          itemCount: mosques.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = mosques[index];
            final distance = _calculateDistance(m);
            final isActive = _prayerLogic.selectedMosque?.slug == m.slug &&
                _prayerLogic.prayerTimeSource == PrayerTimeSource.mosque;
            return Material(
              color: isDark ? const Color(0xFF23232E) : Colors.white,
              child: ListTile(
                onTap: () {
                  _selectMosque(m);
                  // Keep the list visible; the details bottom sheet appears below.
                },
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? const Color(0xFFD64463)
                      : const Color(0xFFD64463).withValues(alpha: 0.12),
                  child: Icon(
                    isActive ? Icons.stars_rounded : Icons.mosque_rounded,
                    color: isActive ? Colors.white : const Color(0xFFD64463),
                    size: 22,
                  ),
                ),
                title: Text(
                  m.name,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _tuneSubtitle(m),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distance != null)
                      Text(
                        _formatKm(distance),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.chevron_left_rounded,
                      color: isActive
                          ? const Color(0xFFD64463)
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _tuneSubtitle(MosquePoint m) {
    final parts = <String>[
      if (m.city.isNotEmpty) m.city,
      m.address ?? '',
    ];
    return parts.where((p) => p.isNotEmpty).join(' • ');
  }

  String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} م';
    return '${km.toStringAsFixed(1)} كم';
  }

  Widget _buildBottomSheet() {
    final m = _selectedMosque!;
    final s = _selectedSchedule;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distance = _calculateDistance(m);
    final isActive = _prayerLogic.selectedMosque?.slug == m.slug &&
        _prayerLogic.prayerTimeSource == PrayerTimeSource.mosque;

    return Material(
      color: isDark ? const Color(0xFF23232E) : Colors.white,
      elevation: 16,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23232E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Mosque Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64463).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Color(0xFFD64463),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14,
                                color: isDark ? Colors.white60 : Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              m.city,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(width: 8),
                              Text('•',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38)),
                              const SizedBox(width: 8),
                              Text(
                                context.loc.mmDistanceKm(distance.toStringAsFixed(1)),
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 13,
                                  color: Color(0xFFD64463),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: context.loc.mmRefreshTimes,
                    onPressed: _selectedMosque != null && !_scheduleLoading
                        ? () => _selectMosque(_selectedMosque!, forceRefresh: true)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _selectedMosque = null),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Active Mosque Badge or Action
              if (isActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        context.loc.mmActiveMosqueBadge,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Prayer Times Grid / Loading
              if (_scheduleLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: Color(0xFFD64463)),
                  ),
                )
              else if (_scheduleError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      _scheduleError!,
                      style: const TextStyle(
                          fontFamily: 'Amiri', color: Colors.red, fontSize: 15),
                    ),
                  ),
                )
              else if (s != null)
                _ScheduleGrid(schedule: s),

              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  // Set as Active Mosque Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.green.shade700
                            : const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        await _prayerLogic.setSelectedMosque(m,
                            schedule: _selectedSchedule);
                        setState(() {
                          _rebuildMarkers();
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.loc.mmAdoptedNow(m.name),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontFamily: 'Amiri'),
                              ),
                              backgroundColor: const Color(0xFF693B42),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.playlist_add_check_rounded,
                          size: 20),
                      label: Text(
                        isActive
                            ? context.loc.mmActiveMosque
                            : context.loc.mmAdoptThis,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Directions Button
                  IconButton.filledTonal(
                    tooltip: context.loc.mmDirections,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C35)
                          : Colors.grey.shade200,
                      foregroundColor: const Color(0xFFD64463),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () async {
                      // Native turn-by-turn first (Google Maps app), then the
                      // browser URL. Never fails silently: the manifest
                      // declares the needed <queries> for Android 11+.
                      final candidates = [
                        Uri.parse(
                            'google.navigation:q=${m.latitude},${m.longitude}'),
                        Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${m.latitude},${m.longitude}'),
                      ];
                      for (final url in candidates) {
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                            return;
                          }
                        } catch (_) {
                          // Try the next candidate.
                        }
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.loc.mmDirectionsFailed,
                              textAlign: TextAlign.right,
                              style:
                                  const TextStyle(fontFamily: 'Amiri'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions_rounded),
                  ),

                  // Share Button
                  IconButton.filledTonal(
                    tooltip: context.loc.mmShare,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C35)
                          : Colors.grey.shade200,
                      foregroundColor: const Color(0xFFD64463),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: s != null
                        ? () {
                            final shareText = '''
${context.loc.mmPrayerTimesFor(m.name, m.city)}
${context.loc.nsPrayerFajr}: ${s.fajr}
${context.loc.nsPrayerSunrise}: ${s.sunrise}
${context.loc.nsPrayerDhuhr}: ${s.dhuhr}
${context.loc.nsPrayerAsr}: ${s.asr}
${context.loc.nsPrayerMaghrib}: ${s.maghrib}
${context.loc.nsPrayerIsha}: ${s.isha}
${s.jumua != null && s.jumua!.isNotEmpty ? context.loc.mmJumua(s.jumua!) : ''}
${context.loc.mmAppName}
''';
                            SharePlus.instance.share(
                              ShareParams(
                                text: shareText,
                                subject: context.loc.mmPrayerTimesFor(m.name, m.city),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.share_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  final MosqueSchedule schedule;

  const _ScheduleGrid({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final prayers = <(String, String, IconData)>[
      (context.loc.nsPrayerFajr, schedule.fajr, Icons.wb_twilight_rounded),
      (context.loc.nsPrayerSunrise, schedule.sunrise, Icons.wb_sunny_rounded),
      (context.loc.nsPrayerDhuhr, schedule.dhuhr, Icons.sunny),
      (context.loc.nsPrayerAsr, schedule.asr, Icons.sunny_snowing),
      (context.loc.nsPrayerMaghrib, schedule.maghrib, Icons.wb_twilight_rounded),
      (context.loc.nsPrayerIsha, schedule.isha, Icons.bedtime_rounded),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final (name, time, icon) = prayers[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C35)
                    : const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: const Color(0xFFD64463)),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time.isNotEmpty ? time : '--:--',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (schedule.jumua != null && schedule.jumua!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF693B42).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: Color(0xFF693B42), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.loc.mmFriday,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF693B42),
                      ),
                    ),
                  ],
                ),
                Text(
                  schedule.jumua!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF693B42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

