import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncButton.dart';
import 'package:ui/widget/AsyncCheckbox.dart';
import 'package:ui/widget/AsyncStringInput.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _agreedToUserAgreement = false;
  bool _agreedToPrivacyPolicy = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double minCardWidth = 700;
            const double spacing = 10;

            final int crossAxisCount = math.max(1, (constraints.maxWidth / (minCardWidth + spacing)).ceil());
            final double cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

            return MasonryGridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              itemCount: 5,
              itemBuilder: (context, index) {
                return switch (index) {
                  0 => SizedBox(width: cardWidth, child: _InfoCard(colorScheme, textScheme)),
                  1 => SizedBox(width: cardWidth, child: _KeyCard(colorScheme, textScheme)),
                  2 => SizedBox(width: cardWidth, child: _UserAgreementCard(colorScheme, textScheme)),
                  3 => SizedBox(width: cardWidth, child: _DisclaimerCard(colorScheme, textScheme)),
                  4 => SizedBox(width: cardWidth, child: _PrivacyPolicyCard(colorScheme, textScheme)),
                  _ => const SizedBox(),
                };
              },
            );
          },
        ),
      ),
    );
  }

  Widget _KeyCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      borderRadius: 10,
      elevation: 2,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('密钥激活', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.vpn_key,
      child: Column(
        children: [
          Row(
            children: [
              Text('设备码：', style: textTheme.titleSmall),
              SelectableText('ABCD-EFGH-IJKL-MNOP', style: textTheme.titleSmall),
              Spacer(),
              AsyncButton(
                onPressed: () async {
                  if (_agreedToUserAgreement && _agreedToPrivacyPolicy) {
                    return true;
                  } else {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text('请先同意用户协议和隐私政策'), duration: Duration(seconds: 2), showCloseIcon: true),
                    );
                    return false;
                  }
                },
                child: Text('复制'),
              ),
            ],
          ),
          SizedBox(height: 10),
          AlertBlock.important(child: Text('请在购买密钥前仔细阅读用户协议、免责声明及隐私政策，购买密钥后即视为同意全部条款。')),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: AsyncStringInput(
                    label: '请输入密钥',
                    textStyle: const TextStyle(fontSize: 14),
                    value: () async => '',
                  ),
                ),
              ),
              SizedBox(width: 10),
              AsyncButton(
                onPressed: () async {
                  if (_agreedToUserAgreement && _agreedToPrivacyPolicy) {
                    return true;
                  } else {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text('请先同意用户协议和隐私政策'), duration: Duration(seconds: 2), showCloseIcon: true),
                    );
                    return false;
                  }
                },
                child: Text('激活'),
              ),
            ],
          ),
          SizedBox(height: 10),
          AlertBlock.warning(child: Text('密钥一经激活立即计时，时长不可暂停、不可转赠、不可退款。')),
          SizedBox(height: 10),
          AlertBlock.tip(child: Text('购买密钥请将设备码发送至客服，获取密钥后在上方输入框中激活。\n请勿通过非官方渠道购买密钥，避免上当受骗。\n请妥善保管密钥，避免丢失泄露。')),
        ],
      ),
    );
  }

  Widget _InfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      title: Row(
        children: [
          Text("人工智能代理执行框架", style: textTheme.titleMedium),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text('Premium', style: textTheme.titleMedium),
                ),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SelectableText("版本: 0.1.0"), SelectableText("构建号: 20251229")],
      ),
    );
  }

  Widget _UserAgreementCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      color: colorScheme.surfaceContainer,
      icon: Icons.gavel,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('用户协议', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            '1. 协议确认\n'
            '本软件为个人开发者独立作品，无任何公开试用版本。您购买密钥即视为已阅读并同意本协议全部内容。\n\n'
            '2. 授权方式\n'
            'a) 采用“密钥+固定时长”模式：1 天/3 天任选，自首次激活时刻起算。\n'
            'b) 密钥一旦激活立即计时，时长不可暂停、不可转赠、不可退款。\n'
            'c) 授权仅限本人同一台设备使用，更换硬件或重装系统视为新设备，需重新购买新密钥。\n\n'
            '3. 费用与退款\n'
            '因个人开发者能力有限，付款成功后不接受任何理由的退款；请在付款前务必确认需求及设备兼容性。\n\n'
            '4. 使用规范\n'
            '不得逆向、破解、共享密钥或利用本软件从事任何违法违规活动；由此产生的全部法律责任由您自行承担，与本人无关。\n\n'
            '5. 更新与停服\n'
            '本人有权随时对软件进行更新、升级或终止分发，无需另行通知，亦不承担后续维护义务。\n\n'
            '6. 责任限制\n'
            '因使用本软件（含第三方修改、分发等行为）所产生的任何直接或间接后果，均由使用者本人承担，'
            '与本软件及其制作者无关；本人对任何损失或法律责任均不承担赔偿责任。\n\n'
            '7. 第三方组件与能力\n'
            'a) 本软件支持加载第三方插件、图像捕获、AI模型、推理后端及鼠标操作接口，上述组件均由第三方独立提供，其运行可能涉及：\n'
            ' - 本地或云端推理；\n'
            ' - 将用户输入（含屏幕图像、窗口标题、鼠标坐标等）传输至第三方服务器；\n'
            ' - 在内存或临时目录中缓存模型、配置、日志。\n'
            'b) 是否启用、启用哪些组件、向谁传输何种数据，完全由您在设置界面中手动选择；开发者不对第三方组件的行为、数据安全、服务质量做任何担保。\n'
            'c) 一旦主动启用任意第三方功能，即视为您已阅读并同意该第三方的用户协议、隐私政策及相关法律文件；由此产生的任何纠纷、赔偿、法律责任均与本人无关。\n'
            'd) 若第三方组件要求额外费用、账号注册或年龄限制，相关义务由您自行承担。\n\n'
            '8. 解释权\n'
            '本协议未尽事宜，开发者保留最终解释权。',
            style: textTheme.titleSmall,
          ),
          Divider(thickness: 1),
          AsyncCheckbox(
            title: Text("我已阅读并同意用户协议", style: textTheme.titleSmall),
            onSelected: (bool selected) async {
              await Future.delayed(Duration(seconds: 1));
              _agreedToUserAgreement = selected;
              return true;
            },
            defaultSelected: false,
            selected: false,
          ),
        ],
      ),
    );
  }

  Widget _DisclaimerCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      color: colorScheme.surfaceContainer,
      icon: Icons.announcement,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('用户协议', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            '1. 本软件按“现状”提供，个人开发者不保证其适用性、稳定性或无错误。\n'
            '2. 因运行环境差异、第三方修改、误操作等导致的任何数据丢失、硬件损坏、账号封禁等后果，'
            '均由使用者自行承担，与本人无关。\n'
            '3. 本人不承诺永久维护，也不对停止更新或下架造成的任何影响负责。\n'
            '4. 若第三方对本软件进行二次修改、打包或分发，由此产生的信息泄露、恶意代码等风险，'
            '均属于第三方个人行为，与本软件及制作者无关。\n'
            '5. 第三方组件特别风险提示\n'
            'a) 第三方AI模型、图像捕获、推理后端或鼠标操作接口可能因算法缺陷、提示词注入、误触发等原因，导致：\n'
            ' - 游戏封号、硬件损坏、系统崩溃；\n'
            ' - 将屏幕内容、账号信息、个人文件上传至境外服务器；\n'
            ' - 被反作弊系统识别为外挂或恶意程序。\n'
            'b) 上述风险概率无法为零，开发者已尽合理提示义务；一旦启用第三方功能，即视为您自愿承担全部后果，本人不承担任何直接、间接或惩罚性赔偿责任。',
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  Widget _PrivacyPolicyCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      color: colorScheme.surfaceContainer,
      title: Row(
        spacing: 5,
        children: [
          Icon(Icons.admin_panel_settings, color: colorScheme.primary),
          Text("隐私政策", style: textTheme.titleMedium),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            '1. 信息收集与使用\n'
            'a) 核心功能：本软件默认仅在本地校验密钥、记录窗口尺寸与主题色、生成设备码等操作，不会上传任何个人身份信息。\n'
            'b) 第三方功能：若您手动启用第三方插件/图像捕获/AI模型/推理后端/鼠标接口，则：\n'
            ' - 该第三方可能收集屏幕图像、窗口标题、鼠标轨迹、硬件指纹、IP地址等；\n'
            ' - 数据可能通过本地回环、局域网或互联网发送至第三方服务器，甚至境外服务器；\n'
            ' - 开发者无法截留、解密或审查上述数据，亦不对其存储时长、使用目的、二次分享负责。\n'
            'c) 启用前，软件会在对应设置页面临时弹出该第三方的隐私政策链接；您必须点击“我已阅读并同意”后方可继续。未启用第三方功能时，本条不适用。\n\n'
            '2. 第三方行为边界\n'
            '任何第三方组件的代码、网络通信、数据存储均由该第三方独立控制；若其违反法律法规或侵害您权益，请联系该第三方维权；本人仅提供集成接口，不构成共同侵权或连带责任。\n\n'
            '3. 儿童隐私\n'
            '本软件不以 18 周岁以下未成年人为目标用户，亦不会刻意收集未成年人信息。\n\n'
            '4. 政策变更\n'
            '本人保留随时更新本政策的权利，变更后的条款自公布之日起生效。',
            style: textTheme.titleSmall,
          ),
          Divider(thickness: 1),
          AsyncCheckbox(
            title: Text("我已阅读并同意隐私政策", style: textTheme.titleSmall),
            onSelected: (bool selected) async {
              await Future.delayed(Duration(seconds: 1));
              _agreedToPrivacyPolicy = selected;
              return true;
            },
            defaultSelected: false,
            selected: false,
          ),
        ],
      ),
    );
  }
}
