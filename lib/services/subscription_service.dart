import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService extends ChangeNotifier {
  static const String _productId = 'com.shotmap.pins.premium.monthly';
  static const String _prefKey = 'is_subscribed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isSubscribed = false;
  bool _isLoading = true;
  bool _isAvailable = false;
  ProductDetails? _product;
  String? _errorMessage;

  bool get isSubscribed => _isSubscribed;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  ProductDetails? get product => _product;
  String? get errorMessage => _errorMessage;

  SubscriptionService() {
    _init();
  }

  Future<void> _init() async {
    // ローカルのサブスクリプション状態を読み込む
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_prefKey) ?? false;

    // Webプラットフォームでは課金不可
    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 購入ストリームを購読
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );

    await _loadProducts();
    await _restorePurchases();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails({_productId});
      if (response.error != null) {
        _errorMessage = response.error!.message;
        return;
      }
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('Restore error: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setSubscribed(true);
        } else if (purchase.status == PurchaseStatus.error) {
          _errorMessage = purchase.error?.message ?? '購入に失敗しました';
          notifyListeners();
        } else if (purchase.status == PurchaseStatus.canceled) {
          _isLoading = false;
          notifyListeners();
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _setSubscribed(bool value) async {
    _isSubscribed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _isLoading = false;
    notifyListeners();
  }

  /// サブスクリプション購入を開始
  Future<bool> subscribe() async {
    if (_product == null) {
      _errorMessage = '商品情報を読み込めませんでした。しばらく待ってから再試行してください。';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: _product!);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = '購入処理中にエラーが発生しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 購入を復元
  Future<void> restore() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = '復元に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
