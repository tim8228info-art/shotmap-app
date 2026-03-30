// ────────────────────────────────────────────────────────────────────────────
// SubscriptionService  v2.0
//
// iOS (StoreKit 経由 in_app_purchase) と
// Android (Google Play Billing 経由 in_app_purchase) 両対応。
//
// ■ 購入フロー
//   1. purchaseMonthlyPlan()      … UI から呼ぶ唯一のエントリポイント
//   2. restorePurchases()         … iOS 必須の「購入を復元」ボタン用
//   3. openAndroidSubscriptionManagement() … Android の解約案内
//
// ■ 状態管理
//   isSubscribed / isLoading / errorMessage を ChangeNotifier で通知
//   購読状態は SharedPreferences に永続化
// ────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionService extends ChangeNotifier {
  // ── 定数 ────────────────────────────────────────────────────────────────
  static const String kProductId  = 'com.shotmap.pins.monthly';
  static const String _kPackageId = 'com.shotmap.pins';
  static const String _prefKey    = 'is_subscribed';

  // ── 内部状態 ─────────────────────────────────────────────────────────────
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStream;

  bool           _isSubscribed  = false;
  bool           _isLoading     = true;
  bool           _isAvailable   = false;
  ProductDetails? _product;
  String?        _errorMessage;

  // ── パブリックゲッター ────────────────────────────────────────────────────
  bool            get isSubscribed  => _isSubscribed;
  bool            get isLoading     => _isLoading;
  bool            get isAvailable   => _isAvailable;
  ProductDetails? get product       => _product;
  String?         get errorMessage  => _errorMessage;

  // ────────────────────────────────────────────────────────────────────────
  // コンストラクタ
  // ────────────────────────────────────────────────────────────────────────
  SubscriptionService() {
    _init();
  }

  // ────────────────────────────────────────────────────────────────────────
  // 初期化
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    // ① ローカルに保存された購読状態を先に読み込む（画面のちらつきを防ぐ）
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_prefKey) ?? false;
    notifyListeners();

    // ② Web は課金非対応
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // ③ iOS: StoreKit デリゲートを設定
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final addition =
            _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await addition.setDelegate(_ShotMapPaymentQueueDelegate());
      } catch (e) {
        _debugLog('initStoreKit error: $e');
      }
    }

    // ④ 共通: ストアの利用可否を確認
    _isAvailable = await _iap.isAvailable();

    if (_isAvailable) {
      // ⑤ 購入イベントストリームを購読
      _purchaseStream = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseStream?.cancel(),
        onError: (Object e) {
          _errorMessage = e.toString();
          notifyListeners();
        },
      );

      // ⑥ 製品情報をロード
      await _loadProducts();

      // ⑦ サイレント復元（起動時に自動で購買状態を同期）
      await _silentRestore();
    } else {
      _debugLog('Store is not available');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────────────
  // ██ パブリック API ██
  // ────────────────────────────────────────────────────────────────────────

  /// 月額プランを購入する（iOS / Android 共通エントリポイント）
  ///
  /// UI の「購入」ボタンからこのメソッドだけを呼ぶ。
  Future<void> purchaseMonthlyPlan() async {
    _clearError();
    _setLoading(true);

    if (_product == null) {
      _errorMessage = '商品情報を読み込めませんでした。しばらく待ってから再試行してください。';
      _setLoading(false);
      return;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // ── iOS: StoreKit (in_app_purchase) ────────────────────────────
        final param = PurchaseParam(productDetails: _product!);
        await _iap.buyNonConsumable(purchaseParam: param);
        // 結果は _onPurchaseUpdate() で処理
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // ── Android: Google Play Billing (in_app_purchase_android) ─────
        final param = GooglePlayPurchaseParam(
          productDetails: _product!,
          changeSubscriptionParam: null,
        );
        await _iap.buyNonConsumable(purchaseParam: param);
        // 結果は _onPurchaseUpdate() で処理
      } else {
        _errorMessage = 'このプラットフォームでは購入できません。';
        _setLoading(false);
      }
    } catch (e) {
      _errorMessage = '購入処理中にエラーが発生しました。\n$e';
      _setLoading(false);
    }
  }

  /// 購入を復元する（iOS 審査必須）
  ///
  /// iOS の「購入を復元する」ボタンに紐付ける。
  /// Android では使用しない（Google Play が自動で同期する）。
  Future<void> restorePurchases() async {
    _clearError();
    _setLoading(true);
    try {
      await _iap.restorePurchases();
      // 結果は _onPurchaseUpdate() で処理
    } catch (e) {
      _errorMessage = '購入の復元に失敗しました。\n$e';
      _setLoading(false);
    }
  }

  /// Android: Google Play の定期購入管理画面を開く
  ///
  /// Google Play ポリシー準拠 – キャンセル導線として提供。
  Future<void> openAndroidSubscriptionManagement() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=$kProductId&package=$_kPackageId',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // 内部ヘルパー
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails({kProductId});
      if (response.error != null) {
        _errorMessage = '商品情報の取得に失敗しました: ${response.error!.message}';
      } else if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        _debugLog('Product loaded: ${_product!.price}');
      } else {
        _debugLog('No product found for $kProductId');
      }
    } catch (e) {
      _debugLog('_loadProducts error: $e');
    }
    notifyListeners();
  }

  Future<void> _silentRestore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      // サイレント失敗 – UI には表示しない
    }
  }

  /// 購入イベントハンドラ（ストリームから呼ばれる）
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> list) async {
    for (final purchase in list) {
      if (purchase.productID != kProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setSubscribed(true);
          _debugLog('Subscription active (${purchase.status})');
          break;

        case PurchaseStatus.error:
          final msg = purchase.error?.message ?? '不明なエラー';
          _errorMessage = '購入に失敗しました: $msg';
          _setLoading(false);
          _debugLog('Purchase error: $msg');
          break;

        case PurchaseStatus.canceled:
          _setLoading(false);
          _debugLog('Purchase canceled');
          break;

        case PurchaseStatus.pending:
          // ペンディング中は何もしない（ローディング表示を維持）
          _debugLog('Purchase pending');
          break;
      }

      // 購入確認を完了させる（必須）
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _setSubscribed(bool value) async {
    _isSubscribed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _debugLog(String msg) {
    if (kDebugMode) debugPrint('[SubscriptionService] $msg');
  }

  // ── deprecated 互換エイリアス（既存コードへの後方互換） ──────────────────
  @Deprecated('Use purchaseMonthlyPlan() instead')
  Future<bool> subscribe() async {
    await purchaseMonthlyPlan();
    return _isSubscribed;
  }

  @Deprecated('Use restorePurchases() instead')
  Future<void> restore() async => restorePurchases();

  // iOS StoreKit 向けのスタブ（後方互換 – 内部で purchaseMonthlyPlan を委譲）
  // ignore: non_constant_identifier_names
  Future<void> purchaseSubscription_iOS(String productID) async =>
      purchaseMonthlyPlan();

  // Android 向けのスタブ（後方互換 – 内部で purchaseMonthlyPlan を委譲）
  // ignore: non_constant_identifier_names
  Future<void> purchaseSubscription_Android(String productID) async =>
      purchaseMonthlyPlan();

  // ────────────────────────────────────────────────────────────────────────
  // Dispose
  // ────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final addition =
            _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        addition.setDelegate(null);
      } catch (_) {}
    }
    _purchaseStream?.cancel();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// iOS StoreKit デリゲート
// プロモーションオファーを許可し、価格変更の同意ダイアログを非表示にする
// ────────────────────────────────────────────────────────────────────────────
class _ShotMapPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) =>
      true;

  @override
  bool shouldShowPriceConsent() => false;
}
