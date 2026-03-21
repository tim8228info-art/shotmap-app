import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

/// Google Map をタップしてピン位置を選択する画面
/// Navigator.push の戻り値として LatLng? を返す
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapPickerScreen({super.key, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;

  // タップで選択した座標
  LatLng? _picked;

  // 選択ピンのマーカー
  Set<Marker> _markers = {};

  // 検索欄
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // クイックスポット（日本主要都市）
  static const List<_QuickSpot> _quickSpots = [
    _QuickSpot('東京', LatLng(35.6895, 139.6917)),
    _QuickSpot('大阪', LatLng(34.6937, 135.5023)),
    _QuickSpot('京都', LatLng(35.0116, 135.7681)),
    _QuickSpot('北海道', LatLng(43.0642, 141.3469)),
    _QuickSpot('沖縄', LatLng(26.2124, 127.6809)),
    _QuickSpot('富士山', LatLng(35.3606, 138.7274)),
    _QuickSpot('広島', LatLng(34.3963, 132.4596)),
    _QuickSpot('福岡', LatLng(33.5904, 130.4017)),
  ];



  @override
  void dispose() {
    _mapController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Google Geocoding API を使って候補一覧を取得 ──
  static const _kGeoApiKey = 'AIzaSyDLgaGTXTjpMQPIkpXB1rlJ_rAolLNecsM';

  // 候補リスト（ドロップダウン表示用）
  List<_GeoResult> _suggestions = [];
  bool _showSuggestions = false;

  // ── 検索バーから地点を検索してマップを移動 ──
  Future<void> _searchPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _suggestions = [];
    });
    try {
      // Google Geocoding API（日本語ロケール・最大5件）
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(q)}'
        '&language=ja'
        '&region=jp'
        '&key=$_kGeoApiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final status = json['status'] as String;
        if (status == 'OK') {
          final results = (json['results'] as List).take(5).toList();
          final candidates = results.map((r) {
            final loc = r['geometry']['location'];
            final lat = (loc['lat'] as num).toDouble();
            final lng = (loc['lng'] as num).toDouble();
            // viewport を使ってズーム自動計算
            double zoom = 14.0;
            try {
              final vp = r['geometry']['viewport'];
              final ne = vp['northeast'];
              final sw = vp['southwest'];
              final latDiff = ((ne['lat'] as num) - (sw['lat'] as num)).abs();
              final lngDiff = ((ne['lng'] as num) - (sw['lng'] as num)).abs();
              final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
              if (maxDiff > 5.0) zoom = 7.0;
              else if (maxDiff > 1.0) zoom = 10.0;
              else if (maxDiff > 0.1) zoom = 13.0;
              else if (maxDiff > 0.01) zoom = 15.5;
              else zoom = 17.0;
            } catch (_) {}
            return _GeoResult(
              label: r['formatted_address'] as String,
              latLng: LatLng(lat, lng),
              zoom: zoom,
            );
          }).toList();

          if (candidates.length == 1) {
            // 1件なら即移動
            _jumpTo(candidates[0].latLng, zoom: candidates[0].zoom);
            _searchCtrl.clear();
            FocusScope.of(context).unfocus();
          } else if (candidates.isNotEmpty) {
            // 複数候補 → ドロップダウン表示
            setState(() {
              _suggestions = candidates;
              _showSuggestions = true;
            });
          } else {
            _showNotFoundSnackBar();
          }
          return;
        } else if (status == 'ZERO_RESULTS') {
          // Google で見つからなかった場合は Nominatim にフォールバック
          await _searchWithNominatim(q);
          return;
        }
      }
      _showNotFoundSnackBar();
    } catch (_) {
      if (!mounted) return;
      // エラー時も Nominatim にフォールバック
      try {
        await _searchWithNominatim(query.trim());
      } catch (_) {
        if (mounted) _showErrorSnackBar();
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── Nominatim フォールバック（countrycodes=jp 指定） ──
  Future<void> _searchWithNominatim(String q) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(q)}'
      '&format=json&limit=5&accept-language=ja&countrycodes=jp',
    );
    final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      if (data.isNotEmpty) {
        if (data.length == 1) {
          final lat = double.tryParse(data[0]['lat'] as String);
          final lng = double.tryParse(data[0]['lon'] as String);
          if (lat != null && lng != null) {
            _jumpTo(LatLng(lat, lng), zoom: 15.0);
            _searchCtrl.clear();
            FocusScope.of(context).unfocus();
            return;
          }
        } else {
          final candidates = data.map((r) {
            final lat = double.tryParse(r['lat'] as String) ?? 35.0;
            final lng = double.tryParse(r['lon'] as String) ?? 135.0;
            final label = (r['display_name'] as String).split(',').take(3).join(',');
            return _GeoResult(label: label, latLng: LatLng(lat, lng), zoom: 15.0);
          }).toList();
          setState(() {
            _suggestions = candidates;
            _showSuggestions = true;
          });
          return;
        }
      }
    }
    _showNotFoundSnackBar();
  }

  void _showNotFoundSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('場所が見つかりませんでした',
          style: GoogleFonts.notoSansJp(fontSize: 13)),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('検索に失敗しました',
          style: GoogleFonts.notoSansJp(fontSize: 13)),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── ピン確定 ──
  void _confirm() {
    Navigator.of(context).pop(_picked);
  }

  // ── キャンセル ──
  void _cancel() {
    Navigator.of(context).pop(null);
  }

  // ── クイックスポットへ移動 ──
  void _jumpTo(LatLng pos, {double zoom = 12.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, zoom),
    );
  }

  // ── マップタップ時 ──
  void _onMapTap(LatLng latLng) async {
    // カスタムマーカーアイコン生成
    final icon = await _createPinIcon();

    setState(() {
      _picked = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('picked'),
          position: latLng,
          icon: icon,
          draggable: true,
          onDragEnd: (newPos) {
            setState(() => _picked = newPos);
          },
        ),
      };
    });
  }

  // ── カスタムピンアイコン生成 ──
  Future<BitmapDescriptor> _createPinIcon() async {
    const size = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // 影
    paint.color = Colors.black.withValues(alpha: 0.2);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 3), size / 2 - 4, paint);

    // グラデーション円
    final gradient = ui.Gradient.radial(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      [AppColors.primaryLight, AppColors.primary],
    );
    paint.shader = gradient;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, paint);
    paint.shader = null;

    // 白い縁
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 6, paint);
    paint.style = PaintingStyle.fill;

    // ピンアイコン（中央の白いロケーションアイコン）
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: '📍',
      style: TextStyle(fontSize: 22),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2,
          size / 2 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  // ── 座標フォーマット ──
  String _formatLatLng(LatLng ll) {
    final lat = ll.latitude.toStringAsFixed(5);
    final lng = ll.longitude.toStringAsFixed(5);
    return 'N$lat, E$lng';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Google Maps 本体 ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter ?? const LatLng(36.5, 137.0),
              zoom: 5.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            mapType: MapType.hybrid,
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── 上部ヘッダー ──
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildStatusBar(),
                const SizedBox(height: 8),
                _buildQuickSpots(),
              ],
            ),
          ),

          // ── 検索候補ドロップダウン ──
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー分のスペース
                    const SizedBox(height: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.list,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '候補から選択してください',
                                    style: GoogleFonts.notoSansJp(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _showSuggestions = false;
                                      _suggestions = [];
                                    }),
                                    child: const Icon(Icons.close,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...List.generate(_suggestions.length, (i) {
                              final s = _suggestions[i];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _showSuggestions = false;
                                    _suggestions = [];
                                  });
                                  _jumpTo(s.latLng, zoom: s.zoom);
                                  _searchCtrl.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16,
                                          color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          s.label,
                                          style: GoogleFonts.notoSansJp(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 中央ヒント（未選択時） ──
          if (_picked == null)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'マップをタップしてピンを立てる',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 下部パネル ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // ── ヘッダー ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancel,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.notoSansJp(fontSize: 13),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchPlace,
                      decoration: InputDecoration(
                        hintText: '地名を入力してEnter...',
                        hintStyle: GoogleFonts.notoSansJp(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // 検索ボタン（ローディング or 虫眼鏡）
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _searchPlace(_searchCtrl.text),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.search, size: 20, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ステータスバー ──
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  _picked == null
                      ? 'マップをタップしてピンを選択'
                      : 'ピン選択済み　再タップで移動',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── クイックスポット横スクロール ──
  Widget _buildQuickSpots() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSpots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final spot = _quickSpots[i];
          return GestureDetector(
            onTap: () => _jumpTo(spot.latLng),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                spot.name,
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 下部パネル ──
  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドルバー
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 選択状態
              if (_picked == null) _buildNoPinMessage() else _buildPickedInfo(_picked!),

              const SizedBox(height: 16),

              // 確定ボタン
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _picked == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _picked == null
                            ? Icons.location_off
                            : Icons.check_circle,
                        size: 20,
                        color: _picked == null
                            ? AppColors.textHint
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _picked == null
                            ? 'マップをタップして場所を選んでください'
                            : 'この場所を投稿先に設定する',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _picked == null
                              ? AppColors.textHint
                              : Colors.white,
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
    );
  }

  Widget _buildNoPinMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryVeryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_searching,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'まだ場所が選択されていません',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'マップ上の好きな場所をタップしてピンを立てましょう',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickedInfo(LatLng ll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F4FC), Color(0xFFD0EBFA)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.location_on,
                size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ピン位置を選択しました ✓',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLatLng(ll),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ドラッグで微調整できます',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _picked = null;
              _markers = {};
            }),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// クイックスポットデータ
class _QuickSpot {
  final String name;
  final LatLng latLng;
  const _QuickSpot(this.name, this.latLng);
}

// 検索候補データ
class _GeoResult {
  final String label;
  final LatLng latLng;
  final double zoom;
  const _GeoResult({required this.label, required this.latLng, required this.zoom});
}
