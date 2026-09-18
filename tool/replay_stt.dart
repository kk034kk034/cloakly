// Run with dart run tool/replay_stt.dart input.pcm output-directory [speed].
// speed=1 preserves real-time pacing; speed=0 tests throughput, not latency.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/stt/soniox_stt.dart';
import 'package:cloakly/services/stt/stt_engine.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/replay_stt.dart input.pcm output-directory [speed=1]',
    );
    exitCode = 64;
    return;
  }
  var key = Platform.environment['SONIOX_API_KEY'] ?? '';
  // Read only the app's own settings; never print credentials.
  final appData = Platform.environment['APPDATA'];
  if (key.isEmpty && appData != null) {
    final prefs = File('$appData/com.cloakly/cloakly/shared_preferences.json');
    if (await prefs.exists()) {
      final data =
          jsonDecode(await prefs.readAsString()) as Map<String, dynamic>;
      key =
          (data['flutter.cloakly.sonioxApiKey'] ??
                  data['cloakly.sonioxApiKey'] ??
                  '')
              as String;
    }
  }
  if (key.isEmpty) {
    stderr.writeln(
      'Missing Soniox key. Set SONIOX_API_KEY locally or save it in Cloakly settings. No audio uploaded.',
    );
    exitCode = 78;
    return;
  }
  final speed = args.length > 2 ? double.parse(args[2]) : 1.0;
  if (!speed.isFinite || speed < 0) throw ArgumentError('speed must be >= 0');
  final output = Directory(args[1]);
  await output.create(recursive: true);
  final log = File('${output.path}/events.jsonl').openWrite();
  final finalLines = <String, TranscriptEvent>{};
  final errors = <String>[];
  var sentBytes = 0;
  final watch = Stopwatch()..start();
  final engine = SonioxStt(
    AppSettings.defaults().copyWith(
      sonioxApiKey: key,
      language: Platform.environment['STT_LANGUAGE'] ?? 'zh-en',
    ),
    lane: SttLane.room,
    elapsedMs: () => sentBytes * 1000 ~/ pcmBytesPerSecond,
  );
  final subscription = engine.events.listen(
    (event) {
      final data = {
        'id': event.utteranceId,
        'text': event.text,
        'speaker': event.speakerLabel,
        'is_final': event.isFinal,
        'removed': event.isRemoved,
        'start_ms': event.startMs,
        'end_ms': event.endMs,
        'received_ms': watch.elapsedMilliseconds,
        'lag_ms_at_1x_only': speed == 1 && event.endMs != null
            ? watch.elapsedMilliseconds - event.endMs!
            : null,
      };
      log.writeln(jsonEncode(data));
      if (event.isFinal) finalLines[event.utteranceId!] = event;
    },
    onError: (Object error) {
      errors.add(error.toString());
      stderr.writeln(error);
    },
  );
  try {
    await engine.start();
    watch.reset();
    final file = await File(args[0]).open();
    try {
      while (errors.isEmpty) {
        final bytes = await file.read(
          3840,
        ); // 120 ms transport frames, not turns.
        if (bytes.isEmpty) break;
        if (bytes.length.isOdd) {
          throw StateError('PCM must contain complete 16-bit samples');
        }
        sentBytes += bytes.length;
        if (speed > 0) {
          final target = (sentBytes * 1000 / pcmBytesPerSecond / speed).round();
          final wait = target - watch.elapsedMilliseconds;
          if (wait > 0) {
            await Future<void>.delayed(Duration(milliseconds: wait));
          }
        }
        engine.addAudio(bytes);
        if (speed == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
      }
    } finally {
      await file.close();
    }
  } catch (error) {
    errors.add(error.toString());
  } finally {
    await engine.stop();
    await subscription.cancel();
    await log.close();
  }
  final lines = finalLines.values.toList()
    ..sort((a, b) => (a.startMs ?? 0).compareTo(b.startMs ?? 0));
  await File('${output.path}/transcript.txt').writeAsString(
    lines
        .map((e) => '[${e.startMs}–${e.endMs} ms] ${e.speakerLabel}: ${e.text}')
        .join('\n'),
  );
  await File('${output.path}/run_report.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'provider': 'soniox',
      'model': 'stt-rt-v5',
      'speed': speed,
      'audio_seconds_sent': sentBytes / pcmBytesPerSecond,
      'wall_seconds': watch.elapsedMilliseconds / 1000,
      'final_utterances': lines.length,
      'model_speaker_labels': lines.map((e) => e.speakerLabel).toSet().toList(),
      'errors': errors,
      'accuracy_status':
          'Requires manual reference; speaker count is not proof of correct attribution.',
    }),
  );
  stdout.writeln(
    'Saved ${lines.length} final utterances; ${errors.length} errors.',
  );
  if (errors.isNotEmpty) exitCode = 1;
}
