import 'package:cloakly/core/theme/app_theme.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TranscriptList extends StatefulWidget {
  const TranscriptList({
    super.key,
    required this.lines,
    this.emptyLabel = '開始後，發言會即時出現在這裡。',
    this.followLatest = false,
    this.selectedIds = const {},
    this.onToggle,
  });
  final List<TranscriptLine> lines;
  final String emptyLabel;
  final bool followLatest;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggle;

  @override
  State<TranscriptList> createState() => _TranscriptListState();
}

class _TranscriptListState extends State<TranscriptList> {
  final _scroll = ScrollController();
  bool _following = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TranscriptList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followLatest && _following && oldWidget.lines != widget.lines) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _following && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return Center(child: Text(widget.emptyLabel));
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if (widget.followLatest &&
                event is ScrollUpdateNotification &&
                (event.dragDetails != null ||
                    _scroll.position.isScrollingNotifier.value)) {
              final following = event.metrics.pixels <= 32;
              if (_following != following) {
                setState(() => _following = following);
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scroll,
            reverse: widget.followLatest,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 64),
            itemCount: widget.lines.length,
            itemBuilder: (context, itemIndex) {
              final index = widget.followLatest
                  ? widget.lines.length - 1 - itemIndex
                  : itemIndex;
              final line = widget.lines[index];
              final selected = widget.selectedIds.contains(line.id);
              return Padding(
                key: ValueKey(line.id),
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: selected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onToggle != null && line.isFinal
                        ? () => widget.onToggle!(line.id)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.onToggle != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: line.isFinal ? null : Colors.grey,
                              ),
                            ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              formatDuration(
                                Duration(milliseconds: line.startMs),
                              ),
                              style: elapsedTimeStyle(context),
                            ),
                          ),
                          SizedBox(
                            width: 78,
                            child: Text(
                              '${line.speaker}${line.isFinal ? '' : '（暫定）'}',
                              style: TextStyle(
                                color: speakerColor(line.speakerIndex),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.text,
                              style: TextStyle(
                                height: 1.45,
                                color: line.isFinal
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                fontStyle: line.isFinal
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.followLatest && !_following)
          Positioned(
            right: 16,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: () {
                setState(() => _following = true);
                _scroll.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_downward),
              label: const Text('回到最新'),
            ),
          ),
      ],
    );
  }
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.busy = false,
    this.startedAt,
  });

  final Suggestion? suggestion;
  final bool busy;
  final DateTime? startedAt;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (suggestion != null) ...[
                  SizedBox(
                    width: 48,
                    child: Text(
                      formatElapsedSince(suggestion!.createdAt, startedAt),
                      style: elapsedTimeStyle(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.lightbulb_outline, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '回答提示',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (suggestion == null)
              Text(
                busy ? '正在根據剛才的對話草擬提示…' : '選取一段或多段發言，再按「建議回覆」。',
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

String formatElapsedSince(DateTime time, [DateTime? startedAt]) {
  final start = startedAt ?? time;
  var ms = time.difference(start).inMilliseconds;
  if (ms < 0) ms = 0;
  return formatDuration(Duration(milliseconds: ms));
}

TextStyle elapsedTimeStyle(BuildContext context) {
  return TextStyle(
    fontSize: 12,
    height: 1.35,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

String formatMeetingWhen(Meeting meeting) {
  final start = DateFormat('yyyy/MM/dd HH:mm').format(meeting.startedAt);
  final end = meeting.endedAt == null
      ? null
      : DateFormat('HH:mm').format(meeting.endedAt!);
  final length = formatDuration(meeting.duration);
  if (end == null) return '$start · $length';
  return '$start–$end · $length';
}
