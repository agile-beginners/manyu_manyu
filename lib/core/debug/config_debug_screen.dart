import 'package:flutter/material.dart';
import '../config/env_config.dart';

/// 設定状態を確認するデバッグ画面
/// デバッグモードでのみ使用可能
class ConfigDebugScreen extends StatelessWidget {
  const ConfigDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debugInfo = EnvConfig.getDebugInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Debug'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: debugInfo.entries.map((entry) {
                  final isConfigured = entry.value == 'Yes';
                  final isApiKey = entry.key.contains('configured');
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isApiKey
                            ? (isConfigured ? Icons.check_circle : Icons.error)
                            : Icons.info,
                        color: isApiKey
                            ? (isConfigured ? Colors.green : Colors.red)
                            : Colors.blue,
                      ),
                      title: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(entry.value),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Copy .env.example to .env\n'
                      '2. Fill in your API keys in .env file\n'
                      '3. Restart the application',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  try {
                    EnvConfig.validateConfiguration();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Configuration is valid!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Configuration error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Validate Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}