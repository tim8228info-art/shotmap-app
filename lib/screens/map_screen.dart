import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart' show FlutterMap, MapController, MapOptions, TileLayer, MarkerLayer;
import 'package:flutter_map/src/layer/marker_layer/marker_layer.dart' as fm show Marker;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';
import '../widgets/ugc/report_block_sheet.dart';
import 'post_screen.dart';

class MapScreen extends StatefulWidget {
  final MapScreenController? controller;
  const MapScreen({super.key, this.controller});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// GlobalKeyでアクセスできるようにするためのラッパー
class MapScreenController {
  _MapScreenState? _state;
  void jumpTo(double lat, double lng) {
    _state?.jumpToLocation(lat, lng);
  }
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  SpotPin? _selectedPin;

  // ピンマーカーセット
  final Map<MarkerId, Marker> _markers = {};

  // マップタイプ（通常↔航空写真）
  MapType _mapType = MapType.hybrid;

  // Web用: flutter_map コントローラー
  final MapController _flutterMapController = MapController();
  // Web用: 航空写真表示フラグ
  bool _webShowSatellite = true;
  // Web用: 現在のカメラ位置
  ll.LatLng _webCenter = const ll.LatLng(36.5, 137.0);
  double _webZoom = 6.0;

  // 検索
  final TextEditingController _searchController = TextEditingController();

  // ピン種別フィルタ（null = 両方表示）
  PinType? _pinTypeFilter;

  // カスタムマーカーアイコン（BitmapDescriptor）
  final Map<String, BitmapDescriptor> _markerIcons = {};

  // Google Mapsスタイル（低彩度）
  static const String _mapStyle = '''
  [
    {"featureType":"all","elementType":"labels.text.fill","stylers":[{"color":"#7c93a3"},{"lightness":"-10"}]},
    {"featureType":"administrative.country","elementType":"geometry","stylers":[{"visibility":"on"}]},
    {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#a0a4a5"}]},
    {"featureType":"landscape","elementType":"geometry.fill","stylers":[{"color":"#dde3e3"}]},
    {"featureType":"poi","elementType":"geometry.fill","stylers":[{"color":"#dde3e3"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d3e2e3"}]},
    {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#a4d8e0"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4d9eae"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _loadMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _flutterMapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SpotPin> get _filteredPins {
    return SampleData.pins.where((p) {
      final matchType = _pinTypeFilter == null || p.pinType == _pinTypeFilter;
      return matchType;
    }).toList();
  }

  // ── カスタムマーカーアイコン生成（ピン種別カラー対応） ──
  Future<BitmapDescriptor> _createCustomMarker(
      String imageUrl, bool isSelected, PinType pinType) async {
    final size = isSelected ? 44.0 : 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // ピン種別カラー
    final pinColor = pinType == PinType.sightseeing
        ? const Color(0xFFE53935) // 赤 = 風景
        : const Color(0xFF1565C0); // 青 = グルメ

    // 影
    paint.color = Colors.black.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(size / 2, size / 2 + 3), size / 2 - 4, paint);

    // 外側のリング（選択時は白、通常もピン色に応じた色）
    paint.color = isSelected ? Colors.white : Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, paint);

    // 内側の背景（ピン種別カラー）
    paint.color = isSelected ? pinColor : pinColor.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6, paint);

    // ピンアイコン（中央）- 風景: 🏔 / グルメ: 🍴
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: pinType == PinType.sightseeing ? '🏔' : '🍴',
      style: TextStyle(fontSize: size * 0.38),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  // ── マーカー読み込み ──
  Future<void> _loadMarkers() async {
    final newMarkers = <MarkerId, Marker>{};

    for (final pin in _filteredPins) {
      final markerId = MarkerId(pin.id);
      final isSelected = _selectedPin?.id == pin.id;

      // キャッシュキー（ピン種別も含める）
      final cacheKey = '${pin.id}_${pin.pinType.name}_${isSelected ? 'sel' : 'nor'}';
      if (!_markerIcons.containsKey(cacheKey)) {
        _markerIcons[cacheKey] =
            await _createCustomMarker(pin.imageUrl, isSelected, pin.pinType);
      }

      newMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(pin.lat, pin.lng),
        icon: _markerIcons[cacheKey]!,
        onTap: () => _onPinTap(pin),
        infoWindow: InfoWindow.noText,
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  // ── ピンタップ時 ──
  void _onPinTap(SpotPin pin) {
    setState(() {
      _selectedPin = _selectedPin?.id == pin.id ? null : pin;
    });
    // 選択されたピンにカメラを移動
    if (_selectedPin != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pin.lat, pin.lng),
          14.0,
        ),
      );
    }
    // マーカーの見た目を更新
    _loadMarkers();
  }

  // ── Google Maps アプリで経路を開く ──
  Future<void> _openGoogleMapsNavigation(SpotPin pin) async {
    // Google Maps アプリ/ブラウザで目的地への経路を表示
    // ユーザーの現在地から pin の座標へのナビ
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${pin.lat},${pin.lng}'
      '&destination_place_id=${Uri.encodeComponent(pin.title)}'
      '&travelmode=driving',
    );

    // ネイティブアプリスキーム（Android/iOS）
    final googleMapsApp = Uri.parse(
      'google.navigation:q=${pin.lat},${pin.lng}&mode=d',
    );

    if (await canLaunchUrl(googleMapsApp)) {
      await launchUrl(googleMapsApp);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Mapsを開けませんでした',
              style: TextStyle(),
            ),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    }
  }

  // ── Google Maps アプリでスポットを表示（ピン付き） ──
  Future<void> _openSpotOnGoogleMaps(SpotPin pin) async {
    // Google Maps でスポット位置をピン付きで表示（場所名付き）
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(pin.title)}'
      '&query_place_id=${pin.lat},${pin.lng}',
    );

    final markerUrl = Uri.parse(
      'https://maps.google.com/maps?q=${pin.lat},${pin.lng}'
      '&ll=${pin.lat},${pin.lng}'
      '&z=15'
      '&t=m'
      // カスタムラベル付きのピン
      '&markers=color:blue%7Clabel:${Uri.encodeComponent(pin.title.characters.first)}%7C${pin.lat},${pin.lng}',
    );

    if (await canLaunchUrl(markerUrl)) {
      await launchUrl(markerUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── 外部から位置ジャンプを受け取る ──
  void jumpToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        14.0,
      ),
    );
  }

  // ── ピン種別フィルタ変更時 ──
  void _onPinTypeFilterChanged(PinType? type) {
    setState(() {
      _pinTypeFilter = type;
      _selectedPin = null;
    });
    _loadMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── マップ本体（Web: flutter_map / モバイル: Google Maps） ──
          if (kIsWeb)
            _buildFlutterMap()
          else
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(36.5, 137.0),
                zoom: 6.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              mapType: _mapType,
              markers: Set<Marker>.of(_markers.values),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onTap: (_) {
                if (_selectedPin != null) {
                  setState(() => _selectedPin = null);
                  _loadMarkers();
                }
              },
            ),

          // ── 上部：フィルタチップのみ（検索バー削除） ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildPinTypeFilterChips(),
              ],
            ),
          ),

          // ── 選択中ピンの詳細カード ──
          if (_selectedPin != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildPinDetailCard(_selectedPin!),
            ),

          // ── 投稿ボタン（右下、詳細カード非表示時のみ） ──
          if (_selectedPin == null)
            Positioned(
              bottom: 24,
              right: 20,
              child: _buildPostButton(),
            ),

          // ── 現在地ボタン ──
          Positioned(
            bottom: _selectedPin == null ? 100 : 200,
            right: 20,
            child: _buildMyLocationButton(),
          ),

          // ── マップタイプ切り替えボタン（Web/モバイル共通） ──
          Positioned(
            bottom: _selectedPin == null ? 160 : 260,
            right: 20,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (kIsWeb) {
                        _webShowSatellite = !_webShowSatellite;
                      } else {
                        _mapType = _mapType == MapType.hybrid
                            ? MapType.normal
                            : MapType.hybrid;
                      }
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      (kIsWeb ? _webShowSatellite : _mapType == MapType.hybrid)
                          ? Icons.map_outlined
                          : Icons.satellite_alt,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (kIsWeb ? _webShowSatellite : _mapType == MapType.hybrid)
                        ? '地図' : '航空',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ── Web用: flutter_map（Esri衛星写真 or OSM通常地図）──
  Widget _buildFlutterMap() {
    final satelliteTileUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    final normalTileUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final tileUrl = _webShowSatellite ? satelliteTileUrl : normalTileUrl;

    return FlutterMap(
      mapController: _flutterMapController,
      options: MapOptions(
        initialCenter: _webCenter,
        initialZoom: _webZoom,
        onTap: (_, __) {
          if (_selectedPin != null) {
            setState(() => _selectedPin = null);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.shotmap.pins',
        ),
        // ピンをマーカーとして表示
        MarkerLayer(
          markers: _filteredPins.map((pin) {
            final isSelected = _selectedPin?.id == pin.id;
            return fm.Marker(
              point: ll.LatLng(pin.lat, pin.lng),
              width: isSelected ? 48 : 38,
              height: isSelected ? 48 : 38,
              child: GestureDetector(
                onTap: () => _onPinTap(pin),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : (pin.pinType == PinType.sightseeing
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1565C0)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      pin.pinType == PinType.sightseeing ? '🏔' : '🍴',
                      style: TextStyle(fontSize: isSelected ? 20 : 16),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 検索バー ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '地名・スポット名で検索',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ピン種別フィルタチップ（両方・風景・グルメ）──
  Widget _buildPinTypeFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPinTypeChip(null, '📍 両方', AppColors.primary),
          const SizedBox(width: 8),
          _buildPinTypeChip(PinType.sightseeing, '⛰️ 風景', const Color(0xFFE53935)),
          const SizedBox(width: 8),
          _buildPinTypeChip(PinType.gourmet, '🍴 グルメ', const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _buildPinTypeChip(PinType? type, String label, Color color) {
    final isSelected = _pinTypeFilter == type;
    return GestureDetector(
      onTap: () => _onPinTypeFilterChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.4),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  // ── ピン詳細カード ──
  Widget _buildPinDetailCard(SpotPin pin) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isSaved = provider.isSavedPin(pin.id);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上段：写真＋情報
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      pin.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.primaryVeryLight,
                        child: const Icon(Icons.image, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ピン種別バッジ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pin.pinType.lightColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pin.pinType.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: pin.pinType.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pin.pinType.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: pin.pinType.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(
                              pin.prefecture,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // タグ ＋ 保存ボタンを同じ行に並べる
                        Row(
                          children: [
                            // タグ（余白を埋める）
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                children: pin.tags.take(2).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.tagBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ── 保存ボタン ──
                            GestureDetector(
                              onTap: () {
                                provider.toggleSavePin(pin);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          isSaved
                                              ? Icons.bookmark_remove
                                              : Icons.bookmark_added,
                                          color: Colors.white, size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isSaved ? '保存を解除しました' : '保存しました ✓',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: isSaved
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSaved
                                      ? const Color(0xFFFFF3CD)
                                      : AppColors.primaryVeryLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSaved
                                        ? const Color(0xFFFFD700)
                                        : AppColors.primaryLight,
                                  ),
                                ),
                                child: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  size: 18,
                                  color: isSaved
                                      ? const Color(0xFFFFAA00)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEEF3F6)),
              const SizedBox(height: 12),

              // 中段：SNSシェアボタン行
              Row(
                children: [
                  Text(
                    'シェア:',
                    style: TextStyle(
                      fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _shareButton(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: const Color(0xFFDD2A7B),
                    onTap: () => _shareToSns(pin, 'instagram'),
                  ),
                  const SizedBox(width: 6),
                  _shareButton(
                    icon: Icons.close,
                    label: 'X',
                    color: const Color(0xFF1A1A1A),
                    onTap: () => _shareToSns(pin, 'x'),
                  ),
                  const SizedBox(width: 6),
                  _shareButton(
                    icon: Icons.link,
                    label: 'コピー',
                    color: AppColors.primary,
                    onTap: () => _copyShareLink(pin),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEF3F6)),
              const SizedBox(height: 12),

              // 下段：ナビボタンのみ（Googleマップで見るボタン削除）
              GestureDetector(
                onTap: () => _openGoogleMapsNavigation(pin),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '経路・ナビ',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            // ── ⚑ 通報ボタン（左上） ──
            Positioned(
              top: -12,
              left: -8,
              child: GestureDetector(
                onTap: () => showReportBlockSheet(
                  context,
                  authorName: pin.authorName,
                  postId: pin.id,
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // ── ×ボタン（右上） ──
            Positioned(
              top: -12,
              right: -8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedPin = null);
                  _loadMarkers();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToSns(SpotPin pin, String platform) async {
    const shotmapUrl = 'https://shotmap.app';
    final shareText = Uri.encodeComponent(
      '📍 ${pin.title}\n${pin.prefecture}\n\nShotmapで発見しました！\n$shotmapUrl\n#shotmap #写真スポット #${pin.prefecture}',
    );
    Uri uri;
    if (platform == 'x') {
      uri = Uri.parse('https://twitter.com/intent/tweet?text=$shareText');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else if (platform == 'instagram') {
      // Instagram はWeb共有をサポートしないため、URLつきでクリップボードコピー
      final copyText = '📍 ${pin.title}（${pin.prefecture}）\n\nShotmapで発見しました！\n$shotmapUrl\n#shotmap #写真スポット';
      await Clipboard.setData(ClipboardData(text: copyText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('テキストをコピーしました（Instagramに貼り付けてください）',
                  style: TextStyle(fontSize: 12)),
            ]),
            backgroundColor: const Color(0xFFDD2A7B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    _copyShareLink(pin);
  }

  void _copyShareLink(SpotPin pin) {
    const shotmapUrl = 'https://shotmap.app';
    final text = '📍 ${pin.title}（${pin.prefecture}）\n\nShotmapで発見しました！\n$shotmapUrl\n#shotmap #写真スポット';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('クリップボードにコピーしました',
                style: TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── 投稿ボタン ──
  Widget _buildPostButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PostScreen()),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // ── 現在地ボタン ──
  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          const LatLng(35.6762, 139.6503), // 東京（デモ用）
          12.0,
        ));
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.my_location,
            color: AppColors.primary, size: 22),
      ),
    );
  }
}
