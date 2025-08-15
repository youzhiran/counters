import 'package:flutter/material.dart';

/// 隐私政策页面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Counters (HarmonyOS版) 隐私政策',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '最后更新时间：2025年8月',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. 信息收集',
              'Counters (HarmonyOS版) 是一款单机局域网计分应用，本应用：\n\n'
              '• 不收集任何个人身份信息\n'
              '• 不收集设备标识符\n'
              '• 不收集位置信息\n'
              '• 不收集通讯录、短信等敏感信息\n\n'
              '应用仅在本地存储游戏数据，不会向任何服务器发送个人信息。',
            ),
            
            _buildSection(
              '2. 本地数据存储',
              '应用会在您的设备本地存储以下数据：\n\n'
              '• 游戏记录和计分数据\n'
              '• 玩家信息（仅限您手动输入的内容）\n'
              '• 应用设置和偏好\n\n'
              '所有数据都存储在您的设备上，我们无法访问这些信息。',
            ),
            
            _buildSection(
              '3. 网络使用',
              'Counters 仅在以下情况下使用本地网络：\n\n'
              '• 局域网多人游戏功能（可选）\n\n'
              '网络功能不会收集或传输任何个人信息。',
            ),
            
            _buildSection(
              '4. 第三方服务',
              '我们不会与第三方分享您的任何信息，因为：\n\n'
              '• 我们不收集个人信息\n'
              '• 所有数据都存储在您的设备上\n'
              '• 没有广告或分析服务',
            ),
            
            _buildSection(
              '5. 数据安全',
              '由于所有数据都存储在您的设备上：\n\n'
              '• 数据安全完全由您控制\n'
              '• 删除应用会清除所有本地数据\n'
              '• 我们无法访问或恢复您的数据',
            ),
            
            _buildSection(
              '6. 儿童隐私',
              'Counters 适合所有年龄段的用户：\n\n'
              '• 不收集任何年龄相关信息\n'
              '• 不针对儿童进行个性化'
            ),
            
            _buildSection(
              '7. 隐私政策更新',
              '我们可能会更新本隐私政策：\n\n'
              '• 您需要同意新政策才能继续使用\n'
              '• 您可以在"设置 > 关于 > 隐私政策"中查看最新版本',
            ),
            
            _buildSection(
              '8. 联系我们',
              '如果您对本隐私政策有任何疑问：\n\n'
              '• 邮箱：2668760098@qq.com\n'
              '• 网站：https://counters.devyi.com/contact\n'
              '• 我们会在7个工作日内回复您的问题',
            ),
            
            const SizedBox(height: 32),
            const Text(
              '感谢您选择 Counters！我们致力于为您提供简单有趣的计分体验。',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
