import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '利用規約',
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
          _buildSection('第1条（適用）', '''
本規約は、Shotmap（以下「本サービス」）が提供するサービスの利用条件を定めるものです。ユーザーの皆様（以下「ユーザー」）には、本規約に従って本サービスをご利用いただきます。
          '''),
          _buildSection('第2条（利用登録）', '''
本サービスにおいては、登録希望者が本規約に同意の上、所定の方法によって利用登録を申請し、運営者がこれを承認することによって利用登録が完了するものとします。

運営者は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあります。

・本規約に違反したことがある者からの申請である場合
・虚偽の事項を届け出た場合
・その他、運営者が利用登録を相当でないと判断した場合
          '''),
          _buildSection('第3条（禁止事項）', '''
ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。

・法令または公序良俗に違反する行為
・犯罪行為に関連する行為
・他のユーザーの個人情報を無断で収集・掲載する行為
・他のユーザーまたは第三者を誹謗・中傷する行為
・他のユーザーまたは第三者の著作権、肖像権その他の権利を侵害する行為
・スパムや迷惑行為
・虚偽の情報を投稿する行為
・本サービスの運営を妨害する行為
・その他、運営者が不適切と判断する行為
          '''),
          _buildSection('第4条（投稿コンテンツ）', '''
ユーザーが本サービスに投稿・掲載したテキスト・画像・位置情報（以下「投稿コンテンツ」）について、ユーザーはその権利を保持するものとします。

ただし、ユーザーが投稿した投稿コンテンツについては、本サービスの改善・宣伝・PR等の目的で運営者が無償で使用できるものとし、ユーザーはこれに同意するものとします。

ユーザーは、投稿コンテンツが第三者の権利を侵害しないことを保証するものとします。
          '''),
          _buildSection('第5条（本サービスの提供の停止等）', '''
運営者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。

・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合
・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合
・コンピュータまたは通信回線等が事故により停止した場合
・その他、運営者が本サービスの提供が困難と判断した場合

運営者は、本サービスの提供の停止または中断により、ユーザーまたは第三者が被ったいかなる不利益または損害についても、一切の責任を負わないものとします。
          '''),
          _buildSection('第6条（利用制限および登録抹消）', '''
運営者は、ユーザーが以下のいずれかに該当する場合には、事前の通知なく、ユーザーに対して本サービスの全部もしくは一部の利用を制限し、またはユーザーとしての登録を抹消することができるものとします。

・本規約のいずれかの条項に違反した場合
・登録事項に虚偽の事実があることが判明した場合
・その他、運営者が本サービスの利用を適当でないと判断した場合
          '''),
          _buildSection('第7条（免責事項）', '''
運営者の債務不履行責任は、運営者の故意または重過失によらない場合には免責されるものとします。

運営者は、本サービスに関して、ユーザーと他のユーザーまたは第三者との間において生じた取引、連絡または紛争等について一切責任を負いません。

本サービスに掲載されるスポット情報・位置情報の正確性について、運営者は保証しません。
          '''),
          _buildSection('第8条（サービス内容の変更等）', '''
運営者は、ユーザーへの事前の告知をもって、本サービスの内容を変更、追加または廃止することがあり、ユーザーはこれに同意するものとします。
          '''),
          _buildSection('第9条（利用規約の変更）', '''
運営者は以下の場合には、ユーザーの個別の同意を要せず、本規約を変更することができるものとします。

・本規約の変更がユーザーの一般の利益に適合するとき
・本規約の変更が本サービス利用契約の目的に反せず、かつ、変更の必要性、変更後の内容の相当性その他の変更に係る事情に照らして合理的なものであるとき

運営者はユーザーに対し、前項による本規約の変更にあたり、事前に、本規約を変更する旨及び変更後の本規約の内容並びにその効力発生時期を通知します。
          '''),
          _buildSection('第10条（準拠法・裁判管轄）', '''
本規約の解釈にあたっては、日本法を準拠法とします。

本サービスに関して紛争が生じた場合には、運営者の本店所在地を管轄する裁判所を専属的合意管轄とします。
          '''),
          _buildFooter('2025年1月1日 制定'),
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
          colors: [AppColors.primaryVeryLight, Color(0xFFD0E8F8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gavel, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shotmap 利用規約',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '本サービスをご利用いただく前に必ずお読みください。',
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
              color: AppColors.primary,
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
              border: Border.all(color: const Color(0xFFE8F0F6)),
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
