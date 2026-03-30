import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import 'map_picker_screen.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _timingController = TextEditingController();

  final List<String> _tags = [];
  String _selectedPref = '東京都';

  // ピン種別（必須）
  PinType? _selectedPinType;

  // 写真スロット（最大5枚）。nullは未選択スロット
  final List<String?> _photos = [null, null, null, null, null];

  bool _submitting = false;

  // ── 位置情報モード ──
  // true = 現在地GPS, false = マップから選択
  bool _useCurrentLocation = true;
  LatLng? _pickedLocation; // マップ選択時の座標
  bool _locationConfirmed = false; // 現在地取得済みフラグ（疑似）

  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県',
    '山形県', '福島県', '茨城県', '栃木県', '群馬県',
    '埼玉県', '千葉県', '東京都', '神奈川県', '新潟県',
    '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県', '滋賀県',
    '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県',
    '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県',
    '鹿児島県', '沖縄県',
  ];

  // 写真スロットのプレースホルダー色
  static const List<Color> _slotColors = [
    Color(0xFFDCEEFA),
    Color(0xFFE3F4FC),
    Color(0xFFD0EBFA),
    Color(0xFFCDE8F8),
    Color(0xFFE8F5FD),
  ];

  int get _photoCount => _photos.where((p) => p != null).length;

  void _tapPhotoSlot(int index) {
    // 実機では image_picker を使う。プレビュー用にダミー画像をセット
    setState(() {
      if (_photos[index] != null) {
        // 既存写真はタップで削除
        _photos[index] = null;
      } else {
        // ダミー: Unsplash の適当な画像
        const dummies = [
          'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
          'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400',
          'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400',
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400',
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400',
        ];
        _photos[index] = dummies[index % dummies.length];
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && _tags.length < 5) {
      setState(() {
        _tags.add(tag.startsWith('#') ? tag : '#$tag');
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
  }

  void _submit() {
    // バリデーション
    if (_selectedPinType == null) {
      _showError('ピンの種類（風景またはグルメ）を選択してください');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showError('スポット名を入力してください');
      return;
    }
    if (_photoCount == 0) {
      _showError('写真を1枚以上追加してください');
      return;
    }
    if (_timingController.text.trim().isEmpty) {
      _showError('おすすめの時間帯・時期を入力してください');
      return;
    }
    // 位置情報バリデーション
    if (_useCurrentLocation && !_locationConfirmed) {
      _showError('「現在地を取得」ボタンを押して位置情報を確認してください');
      return;
    }
    if (!_useCurrentLocation && _pickedLocation == null) {
      _showError('マップからスポットの場所を選択してください');
      return;
    }

    setState(() => _submitting = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_selectedPinType == PinType.sightseeing ? '🔴 風景' : '🔵 グルメ'}ピンを投稿しました！',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: TextStyle()),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _timingController.dispose();
    super.dispose();
  }

  // ─────────────────────────── build ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① ピン種別選択（必須）
              _buildPinTypeSelector(),
              const SizedBox(height: 22),

              // ② 写真（最大5枚）
              _buildPhotoSection(),
              const SizedBox(height: 22),

              // ③ スポット名
              _buildRequiredLabel('スポット名'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: '例: 嵐山 竹林の小径',
              ),
              const SizedBox(height: 18),

              // ④ 都道府県（必須）
              _buildRequiredLabel('都道府県'),
              const SizedBox(height: 8),
              _buildPrefDropdown(),
              const SizedBox(height: 18),

              // ⑤ タグ
              _buildOptionalLabel('タグ（最大5個）'),
              const SizedBox(height: 8),
              _buildTagInput(),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildTagChips(),
              ],
              const SizedBox(height: 18),

              // ⑥ おすすめの時間帯・時期（必須）
              _buildRequiredLabel('おすすめの時間帯・時期'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '例: 早朝5〜7時 / 10〜11月の紅葉シーズン / 夕暮れ時',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _buildTextField(
                controller: _timingController,
                hint: '撮影に最適な時間帯や季節を教えてください☀️',
                maxLines: 3,
              ),
              const SizedBox(height: 22),

              // ⑦ 位置情報
              _buildLocationArea(),
              const SizedBox(height: 32),

              // ⑧ 投稿ボタン（下部にも配置）
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ① ピン種別選択 ───
  Widget _buildPinTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('ピンの種類'),
        const SizedBox(height: 4),
        Text(
          '風景写真スポットは赤ピン、グルメ・飲食店は青ピンで投稿されます',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPinTypeCard(PinType.sightseeing)),
            const SizedBox(width: 12),
            Expanded(child: _buildPinTypeCard(PinType.gourmet)),
          ],
        ),
      ],
    );
  }

  Widget _buildPinTypeCard(PinType type) {
    final isSelected = _selectedPinType == type;
    final color = type.color;
    final lightColor = type.lightColor;
    final label = type.label;
    final icon = type.icon;
    final desc = type == PinType.sightseeing
        ? '絶景・名所・観光地\n自然・建築・景色'
        : 'レストラン・カフェ\n食べ歩き・グルメ';

    return GestureDetector(
      onTap: () => setState(() => _selectedPinType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFDDE3E8),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            // ピンアイコン
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            // ラベル
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$label ピン',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (isSelected) ...[  
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '選択中',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        '新しいスポットを投稿',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '投稿する',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── ① 写真セクション（最大5枚グリッド） ───
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildRequiredLabel('写真'),
            const SizedBox(width: 8),
            // カウンターバッジ
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _photoCount > 0
                    ? AppColors.primary
                    : AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_photoCount / 5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _photoCount > 0 ? Colors.white : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '最大5枚',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 1枚目（メイン・大きい） + 2〜5枚目（小さいグリッド）
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // メイン写真スロット
            Expanded(
              flex: 5,
              child: _buildPhotoSlot(0, isMain: true),
            ),
            const SizedBox(width: 8),
            // サブ写真 2×2グリッド
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildPhotoSlot(1)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPhotoSlot(2)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildPhotoSlot(3)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPhotoSlot(4)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          '※ 1枚目がメイン写真としてマップに表示されます',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index, {bool isMain = false}) {
    final hasPhoto = _photos[index] != null;
    final slotHeight = isMain ? 160.0 : 74.0;

    return GestureDetector(
      onTap: () => _tapPhotoSlot(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: slotHeight,
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.transparent : _slotColors[index],
          borderRadius: BorderRadius.circular(isMain ? 16 : 12),
          border: Border.all(
            color: hasPhoto
                ? Colors.transparent
                : AppColors.primaryLight,
            width: 1.5,
          ),
          boxShadow: hasPhoto
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMain ? 16 : 12),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _photos[index]!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.image,
                            color: Colors.white),
                      ),
                    ),
                    // 削除ヒントオーバーレイ
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.white),
                      ),
                    ),
                    if (isMain && index == 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'メイン',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMain ? Icons.add_a_photo_outlined : Icons.add_photo_alternate_outlined,
                        size: isMain ? 30 : 20,
                        color: AppColors.primary,
                      ),
                      if (isMain) ...[
                        const SizedBox(height: 6),
                        Text(
                          '写真を追加',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'タップして選択',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── ラベル ───
  Widget _buildRequiredLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.tagPink,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '必須',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ─── テキストフィールド ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.textHint,
          height: 1.5,
        ),
      ),
    );
  }

  // ─── 都道府県ドロップダウン ───
  Widget _buildPrefDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryVeryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPref,
          isExpanded: true,
          items: _prefectures.map((pref) {
            return DropdownMenuItem(
              value: pref,
              child: Text(pref, style: TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedPref = val);
          },
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        ),
      ),
    );
  }

  // ─── タグ入力 ───
  Widget _buildTagInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _tagController,
            onSubmitted: (_) => _addTag(),
            decoration: const InputDecoration(
              hintText: '例: 写真映え、紅葉',
              prefixText: '# ',
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _addTag,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _tags.length >= 5
                  ? AppColors.textHint
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _tags.asMap().entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tagBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeTag(entry.key),
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.primary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── 位置情報セクション（必須） ───
  Widget _buildLocationArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル行
        Row(
          children: [
            Text(
              'スポットの場所',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tagPink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '必須',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // モード切替トグル
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryVeryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Row(
            children: [
              // 現在地タブ
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useCurrentLocation = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _useCurrentLocation
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _useCurrentLocation
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 15,
                          color: _useCurrentLocation
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '現在地を使用',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _useCurrentLocation
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // マップ選択タブ
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useCurrentLocation = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: !_useCurrentLocation
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_useCurrentLocation
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 15,
                          color: !_useCurrentLocation
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'マップで選択',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_useCurrentLocation
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // モード別コンテンツ
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _useCurrentLocation
              ? _buildCurrentLocationPanel()
              : _buildMapPickerPanel(),
        ),
      ],
    );
  }

  // ── 現在地パネル ──
  Widget _buildCurrentLocationPanel() {
    return Container(
      key: const ValueKey('current'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _locationConfirmed
            ? const Color(0xFFE8F8F0)
            : AppColors.primaryVeryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _locationConfirmed
              ? const Color(0xFF2ECC71)
              : AppColors.primaryLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _locationConfirmed
                  ? const Color(0xFF2ECC71)
                  : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _locationConfirmed ? Icons.check : Icons.my_location,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationConfirmed ? '現在地を取得しました ✓' : 'GPSで現在地を取得',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _locationConfirmed
                        ? const Color(0xFF1A9852)
                        : AppColors.primaryDark,
                  ),
                ),
                Text(
                  _locationConfirmed
                      ? '位置情報が投稿に含まれます'
                      : 'ボタンを押して現在地を確認',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 取得ボタン
          if (!_locationConfirmed)
            GestureDetector(
              onTap: () {
                // 実機では geolocator で取得。デモ用に即時確認
                setState(() => _locationConfirmed = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '取得',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _locationConfirmed = false),
              child: Text(
                'リセット',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── マップ選択パネル ──
  Widget _buildMapPickerPanel() {
    return GestureDetector(
      key: const ValueKey('map'),
      onTap: _openMapPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pickedLocation != null
              ? const Color(0xFFE3F4FC)
              : AppColors.primaryVeryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pickedLocation != null
                ? AppColors.primary
                : AppColors.primaryLight,
          ),
        ),
        child: _pickedLocation == null
            ? _buildMapPickerEmpty()
            : _buildMapPickerSelected(_pickedLocation!),
      ),
    );
  }

  Widget _buildMapPickerEmpty() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_location_alt_outlined,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'マップからスポットの場所を選択',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'タップしてマップを開く →',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.primary),
      ],
    );
  }

  Widget _buildMapPickerSelected(LatLng ll) {
    final latStr = ll.latitude.toStringAsFixed(5);
    final lngStr = ll.longitude.toStringAsFixed(5);
    return Row(
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
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ピン位置を選択済み ✓',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'N$latStr, E$lngStr',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: _openMapPicker,
                child: Text(
                  '変更する →',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _pickedLocation = null),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // ── MapPickerScreen を開いて結果を受け取る ──
  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPickerScreen(
          initialCenter: _pickedLocation,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result;
      });
    }
  }

  // ─── 下部 投稿ボタン ───
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'スポットを投稿する',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
