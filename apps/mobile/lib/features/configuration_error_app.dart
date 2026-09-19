import 'package:flutter/material.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.settings_suggest_outlined, size: 52),
                    SizedBox(height: 20),
                    Text(
                      '手機 Hosted 版尚未設定',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    SelectableText(
                      '請使用 --dart-define 提供 SUPABASE_URL 和 '
                      'SUPABASE_PUBLISHABLE_KEY。RevenueCat 金鑰可在完成商店設定後加入。',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
