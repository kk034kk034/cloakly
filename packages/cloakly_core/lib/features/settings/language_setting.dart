import 'package:cloakly_core/l10n/app_language.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-line language choice. Height does not change with the selection or
/// with which label is showing, so screens that pin actions below it stay put.
class LanguageSetting extends ConsumerWidget {
  const LanguageSetting({super.key});

  static const double controlHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(appLanguageProvider);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: controlHeight,
          child: SegmentedButton<AppLanguageChoice>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: WidgetStatePropertyAll(Size(0, controlHeight)),
              maximumSize: WidgetStatePropertyAll(
                Size(double.infinity, controlHeight),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
            segments: [
              ButtonSegment(
                value: AppLanguageChoice.system,
                label: _Label(l10n.languageSystem),
              ),
              ButtonSegment(
                value: AppLanguageChoice.zhHant,
                label: _Label(l10n.languageZhHant),
              ),
              ButtonSegment(
                value: AppLanguageChoice.en,
                label: _Label(l10n.languageEnglish),
              ),
            ],
            selected: {choice},
            onSelectionChanged: (selection) {
              ref.read(appLanguageProvider.notifier).setChoice(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
  }
}
