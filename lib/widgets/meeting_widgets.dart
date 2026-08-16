import 'package:cloakly/core/theme/app_theme.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:flutter/material.dart';

class TranscriptList extends StatelessWidget {
  const TranscriptList({
    super.key,
    required this.lines,
    this.emptyLabel = '開始後，發言會即時出現在這裡。',
  });

  final List<TranscriptLine> lines;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final showSpeaker = index == 0 ||
            lines[index - 1].speakerIndex != line.speakerIndex ||
            lines[index - 1].speaker != line.speaker;
        return Padding(
          padding: EdgeInsets.only(top: showSpeaker ? 14 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: showSpeaker
                    ? Text(
                        line.speaker,
                        style: TextStyle(
                          color: speakerColor(line.speakerIndex),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  line.text,
                  style: TextStyle(
                    height: 1.45,
                    color: line.isFinal
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: line.isFinal ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.busy = false,
  });

  final Suggestion? suggestion;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '回答提示',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (busy) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (suggestion == null)
              Text(
                busy ? '正在根據剛才的對話草擬提示…' : '對方提問或你按下「給我提示」後，建議會出現在這裡。',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              )
            else ...[
              if (suggestion!.triggerText.isNotEmpty) ...[
                Text(
                  '針對：${suggestion!.triggerText}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SelectableText(
                suggestion!.answer,
                style: const TextStyle(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$seconds';
  return '$minutes:$seconds';
}
