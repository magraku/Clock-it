import 'package:flutter/material.dart';

import '../strings.dart';

Future<void> showLegalScreen(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const LegalScreen()),
    );

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(Str.legal)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(Str.privacyTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(Str.privacyNotice),
                const SizedBox(height: 24),
                Text(Str.termsTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(Str.termsOfUse),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
