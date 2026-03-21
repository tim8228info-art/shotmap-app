import 'package:flutter/foundation.dart';
import '../models/data_models.dart';

/// ユーザープロフィールの状態管理 Provider
/// ・プロフィール編集（カスタムID含む）
/// ・スポット保存（マップピン / トレンド）
/// ・フォロー / フォロワー管理
class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = SampleData.initialUser;

  // ── 保存済みスポット ──
  final List<SavedSpot> _savedSpots = [];

  // ── フォロー中のユーザーUID一覧 ──
  final Set<String> _followingUids = {};

  // ── 既存カスタムIDの仮想レジストリ（重複チェック用・本番はサーバーで管理）──
  // サンプルユーザーのIDを初期登録
  final Set<String> _registeredIds = {
    'yuki_travel',
    'mio_photo',
    'kenji_tokyo',
    'hana_kyoto',
    'osaka_night',
    'aoi_asakusa',
    'riku_shrine',
    'nana_shirakawa',
  };

  // ──────── ゲッター ────────

  UserProfile get profile => _profile;
  String get name => _profile.name;
  String get bio => _profile.bio;
  String get avatarUrl => _profile.avatarUrl;
  int get pinCount => _profile.pinCount;
  int get likeCount => _profile.likeCount;
  String get customId => _profile.customId;

  String get instagramUrl => _profile.instagramUrl;
  String get youtubeUrl => _profile.youtubeUrl;
  String get xUrl => _profile.xUrl;
  String get tiktokUrl => _profile.tiktokUrl;

  bool get hasInstagram => _profile.instagramUrl.trim().isNotEmpty;
  bool get hasYoutube => _profile.youtubeUrl.trim().isNotEmpty;
  bool get hasX => _profile.xUrl.trim().isNotEmpty;
  bool get hasTiktok => _profile.tiktokUrl.trim().isNotEmpty;

  /// フォロー一覧を他ユーザーから非公開にするか
  bool get hideFollowing => _profile.hideFollowing;

  // 保存済みスポット（新着順）
  List<SavedSpot> get savedSpots {
    final sorted = List<SavedSpot>.from(_savedSpots)
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(sorted);
  }

  // フォロー中UID一覧
  Set<String> get followingUids => Set.unmodifiable(_followingUids);
  int get followingCount => _followingUids.length;

  // ──────── プロフィール更新 ────────

  /// プロフィールをまとめて更新
  void updateProfile({
    required String name,
    required String bio,
    required String customId,
    required String instagramUrl,
    required String youtubeUrl,
    required String xUrl,
    required String tiktokUrl,
    bool? hideFollowing,
  }) {
    final oldId = _profile.customId.trim().toLowerCase();
    final newId = customId.trim().toLowerCase();

    // カスタムIDが変わる場合、古いIDをレジストリから削除して新しいIDを登録
    if (oldId.isNotEmpty && oldId != newId) {
      _registeredIds.remove(oldId);
    }
    if (newId.isNotEmpty) {
      _registeredIds.add(newId);
    }

    _profile = _profile.copyWith(
      name: name.trim().isEmpty ? 'あなたの名前' : name.trim(),
      bio: bio.trim(),
      customId: newId,
      instagramUrl: instagramUrl.trim(),
      youtubeUrl: youtubeUrl.trim(),
      xUrl: xUrl.trim(),
      tiktokUrl: tiktokUrl.trim(),
      hideFollowing: hideFollowing,
    );
    notifyListeners();
  }

  /// アバター画像URLのみ更新
  void updateAvatar(String url) {
    _profile = _profile.copyWith(avatarUrl: url);
    notifyListeners();
  }

  // ──────── カスタムID ────────

  /// カスタムIDの重複チェック（true = 使用可能）
  bool isCustomIdAvailable(String id) {
    final normalized = id.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    // 自分の現在のIDは使用可能
    if (normalized == _profile.customId.trim().toLowerCase()) return true;
    return !_registeredIds.contains(normalized);
  }

  /// カスタムIDのバリデーション
  String? validateCustomId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null; // 空でもOK（任意）
    if (trimmed.length < 3) return '3文字以上で入力してください';
    if (trimmed.length > 20) return '20文字以内で入力してください';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return '半角英数字とアンダースコア(_)のみ使用できます';
    }
    if (!isCustomIdAvailable(trimmed)) {
      return 'このIDはすでに使用されています';
    }
    return null; // OK
  }

  // ──────── 保存機能 ────────

  /// マップピンを保存
  void savePin(SpotPin pin) {
    if (!isSavedPin(pin.id)) {
      _savedSpots.add(SavedSpot.fromPin(pin));
      notifyListeners();
    }
  }

  /// マップピンの保存解除
  void unsavePin(String pinId) {
    _savedSpots.removeWhere((s) => s.id == pinId && s.type == SavedSpotType.pin);
    notifyListeners();
  }

  /// トレンドスポットを保存
  void saveTrend(TrendSpot trend) {
    if (!isSavedTrend(trend.id)) {
      _savedSpots.add(SavedSpot.fromTrend(trend));
      notifyListeners();
    }
  }

  /// トレンドスポットの保存解除
  void unsaveTrend(String trendId) {
    _savedSpots.removeWhere(
        (s) => s.id == trendId && s.type == SavedSpotType.trend);
    notifyListeners();
  }

  bool isSavedPin(String pinId) =>
      _savedSpots.any((s) => s.id == pinId && s.type == SavedSpotType.pin);

  bool isSavedTrend(String trendId) =>
      _savedSpots.any((s) => s.id == trendId && s.type == SavedSpotType.trend);

  void toggleSavePin(SpotPin pin) {
    if (isSavedPin(pin.id)) {
      unsavePin(pin.id);
    } else {
      savePin(pin);
    }
  }

  void toggleSaveTrend(TrendSpot trend) {
    if (isSavedTrend(trend.id)) {
      unsaveTrend(trend.id);
    } else {
      saveTrend(trend);
    }
  }

  // ──────── フォロー機能 ────────

  bool isFollowing(String uid) => _followingUids.contains(uid);

  void follow(String uid) {
    _followingUids.add(uid);
    notifyListeners();
  }

  void unfollow(String uid) {
    _followingUids.remove(uid);
    notifyListeners();
  }

  void toggleFollow(String uid) {
    if (isFollowing(uid)) {
      unfollow(uid);
    } else {
      follow(uid);
    }
  }

  /// フォロー中のユーザーリストを AppUser リストで返す
  List<AppUser> get followingUsers => SampleData.sampleUsers
      .where((u) => _followingUids.contains(u.uid))
      .toList();
}
