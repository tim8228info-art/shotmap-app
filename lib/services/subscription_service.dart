// ────────────────────────────────────────────────────────────────────────────
// SubscriptionService
//
// iOS (StoreKit) と Android (Google Play Billing) 両対応の
// サブスクリプション管理サービス。
//
// ■ スタブ関数（後で実装）:
//   - purchaseMonthlyPlan()        → 月額プランを購入（iOS / Android 共通エントリ）
//   - purchaseSubscription_iOS()   → iOS StoreKit 購入処理（Xcodeで実装）
//   - purchaseSubscription_Android() → Android Google Play 購入処理
//   - restorePurchases()           → iOS: 購入を復元（Apple 規定）
//   - openAndroidSubscriptionManagement() → Android: 定期購入管理画面を開く
//   - initStoreKit()               → iOS StoreKit を初期化
//   - initGoogleBilling()          → Android Google Billing を初期化
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
  /// App Store Connect / Google Play Console に登録した製品 ID
  static const String kProductId = 'com.shotmap.pins.monthly';
  static const String _prefKey = 'is_subscribed';
  static const String _kPackageId = 'com.shotmap.pins';

  // ── 内部状態 ─────────────────────────────────────────────────────────────
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStream;

  bool _isSubscribed = false;
  bool _isLoading = true;
  bool _isAvailable = false;
  ProductDetails? _product;
  String? _errorMessage;

  // ── パブリックゲッター ────────────────────────────────────────────────────
  bool get isSubscribed => _isSubscribed;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  ProductDetails? get product => _product;
  String? get errorMessage => _errorMessage;

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
    // ローカルに保存された購読状態を復元
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_prefKey) ?? false;
    notifyListeners();

    // Web は課金非対応
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // プラットフォーム別の初期化
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await initStoreKit();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await initGoogleBilling();
    }

    // 共通: 製品情報を取得してサイレント復元
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      _purchaseStream = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseStream?.cancel(),
        onError: (Object e) {
          _errorMessage = e.toString();
          notifyListeners();
        },
      );
      await _loadProducts();
      await _silentRestore();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────────────
  // ██ スタブ関数群 ██
  // ────────────────────────────────────────────────────────────────────────

  /// 【スタブ】iOS: StoreKit を初期化する
  /// → Xcode ビルド時に実際の初期化処理を記述してください
  Future<void> initStoreKit() async {
    // TODO(iOS): StoreKit の初期化処理
    // 例: SKPaymentQueueDelegate の設定など
    try {
      final iosPlatformAddition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition
          .setDelegate(_ShotMapPaymentQueueDelegate());
    } catch (e) {
      if (kDebugMode) debugPrint('[SubscriptionService] initStoreKit error: $e');
    }
  }

  /// 【スタブ】Android: Google Play Billing を初期化する
  /// → Android ビルド時に実際の初期化処理を記述してください
  Future<void> initGoogleBilling() async {
    // TODO(Android): Google Play Billing の初期化処理
    // 例: BillingClient の設定、接続確認など
    if (kDebugMode) {
      debugPrint('[SubscriptionService] initGoogleBilling called');
    }
  }

  /// 【スタブ】月額プランを購入する（iOS / Android 共通エントリポイント）
  ///
  /// 実装時はこのメソッドを呼び出すだけで OK。
  /// 内部でプラットフォームを判定して適切なメソッドに振り分けます。
  Future<void> purchaseMonthlyPlan() async {
    _clearError();
    _setLoading(true);

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await purchaseSubscription_iOS(kProductId);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await purchaseSubscription_Android(kProductId);
      } else {
        // Web / デスクトップ: 非対応
        _errorMessage = 'このプラットフォームでは購入できません。';
        _setLoading(false);
      }
    } catch (e) {
      _errorMessage = '購入処理中にエラーが発生しました。\n$e';
      _setLoading(false);
    }
  }

  /// 【スタブ】iOS 向け StoreKit 購入処理
  /// → Xcode でこのメソッドに実際の StoreKit 処理を実装してください
  // ignore: non_constant_identifier_names
  Future<void> purchaseSubscription_iOS(String productID) async {
    // TODO(iOS): StoreKit を使用した購入処理を実装
    // 例:
    //   final purchaseParam = PurchaseParam(productDetails: _product!);
    //   await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (_product == null) {
      _errorMessage = '商品情報を読み込めませんでした。';
      _setLoading(false);
      return;
    }
    final purchaseParam = PurchaseParam(productDetails: _product!);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 【スタブ】Android 向け Google Play Billing 購入処理
  /// → Android ビルド時にこのメソッドに実際の Billing 処理を実装してください
  // ignore: non_constant_identifier_names
  Future<void> purchaseSubscription_Android(String productID) async {
    // TODO(Android): Google Play Billing を使用した購入処理を実装
    // 例:
    //   final purchaseParam = GooglePlayPurchaseParam(
    //     productDetails: _product!,
    //     changeSubscriptionParam: null,
    //   );
    //   await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (_product == null) {
      _errorMessage = '商品情報を読み込めませんでした。';
      _setLoading(false);
      return;
    }
    final purchaseParam = GooglePlayPurchaseParam(
      productDetails: _product!,
      changeSubscriptionParam: null,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 【スタブ】iOS: 購入を復元する（Apple 審査必須）
  ///
  /// iOS アプリには Restore Purchase ボタンが必須です。
  /// このメソッドを UI の「購入を復元する」ボタンに紐付けてください。
  Future<void> restorePurchases() async {
    // TODO(iOS): 必要に応じて追加のリストア処理を実装
    _clearError();
    _setLoading(true);
    try {
      await _iap.restorePurchases();
      // 結果は _onPurchaseUpdate で処理される
    } catch (e) {
      _errorMessage = '購入の復元に失敗しました。\n$e';
      _setLoading(false);
    }
  }

  /// 【スタブ】Android: Google Play の定期購入管理画面を開く
  ///
  /// Google Play ポリシーに従い、ユーザーが簡単に解約できる
  /// Google Play の管理画面へ誘導してください。
  Future<void> openAndroidSubscriptionManagement() async {
    // TODO(Android): 必要に応じてカスタムの管理画面 URL を設定
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=$kProductId&package=$_kPackageId',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // 内部ヘルパー（変更不要）
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails({kProductId});
      if (response.error != null) {
        _errorMessage = response.error!.message;
      } else if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SubscriptionService] _loadProducts: $e');
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

  void _onPurchaseUpdate(List<PurchaseDetails> list) async {
    for (final purchase in list) {
      if (purchase.productID != kProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setSubscribed(true);
          break;
        case PurchaseStatus.error:
          _errorMessage = purchase.error?.message ?? '購入に失敗しました。';
          _setLoading(false);
          break;
        case PurchaseStatus.canceled:
          _setLoading(false);
          break;
        case PurchaseStatus.pending:
          break;
      }

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

  // ── deprecated 互換エイリアス（既存コードを壊さないため） ────────────────
  /// [purchaseMonthlyPlan] を使用してください
  @Deprecated('Use purchaseMonthlyPlan() instead')
  Future<bool> subscribe() async {
    await purchaseMonthlyPlan();
    return _isSubscribed;
  }

  /// [restorePurchases] を使用してください
  @Deprecated('Use restorePurchases() instead')
  Future<void> restore() async => restorePurchases();

  // ────────────────────────────────────────────────────────────────────────
  // Dispose
  // ────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final iosPlatformAddition =
            _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        iosPlatformAddition.setDelegate(null);
      } catch (_) {}
    }
    _purchaseStream?.cancel();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// iOS StoreKit デリゲート（プロモーションオファー対応）
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
