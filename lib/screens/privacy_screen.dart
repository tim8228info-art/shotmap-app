import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'プライバシーポリシー',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.primary, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSection('1. 収集する情報', '''
本サービスでは、以下の情報を収集する場合があります。

【ユーザーが提供する情報】
・ニックネーム・プロフィール画像などのプロフィール情報
・投稿するスポット情報（タイトル・写真・説明文・タグ）
・位置情報（スポット登録時に任意で提供）
・SNSリンク（Instagram、YouTube、X、TikTok）

【自動的に収集される情報】
・アプリの利用状況・操作ログ
・デバイス情報（OS、端末種別）
・IPアドレス
          '''),
          _buildSection('2. 情報の利用目的', '''
収集した情報は、以下の目的で利用します。

・本サービスの提供・運営・改善
・ユーザーへのサービスに関する通知
・利用規約違反行為の調査・対応
・スパムや不正行為の防止
・統計データの作成（個人を特定しない形式）
・新機能・アップデートのご案内

収集した個人情報は、ユーザーの同意なく上記以外の目的で使用することはありません。
          '''),
          _buildSection('3. 位置情報について', '''
本サービスでは、スポット投稿時にGPSによる位置情報を取得することがあります。

・位置情報の取得は任意であり、ユーザーの許可なしに取得することはありません
・取得した位置情報は、スポットのマップ表示のみに使用します
・位置情報は投稿されたスポット情報に紐付けられ、他のユーザーに公開されます
・スマートフォンの設定から位置情報の利用許可をいつでも変更できます
          '''),
          _buildSection('4. 情報の第三者提供', '''
運営者は、以下の場合を除き、ユーザーの個人情報を第三者に提供しません。

・ユーザーの同意がある場合
・法令に基づく場合
・人の生命・身体または財産の保護のために必要であり、かつユーザーの同意を得ることが困難である場合
・国の機関または地方公共団体が法令の定める事務を遂行することに協力する必要がある場合

本サービスは以下のサービスを利用しており、これらのプライバシーポリシーも適用される場合があります。

・Google Maps Platform（地図表示・位置情報）
・Firebase（データ管理・認証）
          '''),
          _buildSection('5. 写真・画像データの取り扱い', '''
ユーザーが投稿した写真・画像は以下のように取り扱います。

・投稿された写真はサービス内で公開されます
・他のユーザーがその写真を閲覧できます
・一度公開された写真は、投稿を削除することで非公開にできます
・写真に含まれる位置情報（EXIF）は、投稿時に削除処理を行います
          '''),
          _buildSection('6. セキュリティ', '''
運営者は、ユーザーの個人情報について、漏えい・滅失・毀損の防止その他の個人情報の安全管理のために、適切なセキュリティ対策を講じます。

ただし、インターネット上での完全なセキュリティを保証するものではありません。ユーザーご自身でも適切な対策をお取りください。
          '''),
          _buildSection('7. Cookieの使用', '''
本サービスのウェブ版では、サービスの利便性向上のためCookieを使用する場合があります。

Cookieはユーザーの同意により無効にすることができますが、一部の機能が利用できなくなる場合があります。
          '''),
          _buildSection('8. 未成年者のプライバシー', '''
本サービスは13歳未満の方を対象としていません。13歳未満の方の個人情報を意図的に収集することはありません。

保護者の方で、お子様が個人情報を提供したと思われる場合は、速やかにご連絡ください。
          '''),
          _buildSection('9. 個人情報の開示・訂正・削除', '''
ユーザーは、本サービスが保有するご自身の個人情報について、開示・訂正・削除を請求することができます。

請求に際しては、本人確認を行った上で対応します。
お問い合わせは、アプリ内のお問い合わせフォームよりご連絡ください。
          '''),
          _buildSection('10. プライバシーポリシーの変更', '''
運営者は、必要に応じて本ポリシーを変更することがあります。

重要な変更を行う場合は、アプリ内での通知またはメールにてお知らせします。

変更後も本サービスの利用を継続した場合、変更後のプライバシーポリシーに同意したものとみなします。
          '''),
          _buildSection('11. お問い合わせ', '''
個人情報の取り扱いに関するご質問・ご意見は、アプリ内のお問い合わせフォーム、またはサポートページよりご連絡ください。

誠意をもって対応いたします。
          '''),
          _buildFooter('2025年1月1日 制定\n最終更新：2025年1月1日'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFD0F0E8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00897B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.privacy_tip, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shotmap プライバシーポリシー',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'お客様の個人情報の取り扱いについて説明します。',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F2F1)),
            ),
            child: Text(
              body.trim(),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          date,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
