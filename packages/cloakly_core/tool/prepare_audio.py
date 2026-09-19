"""Decode a complete recording locally for repeatable streaming evaluation.

Uses PyAV. Does not upload audio or modify the source recording.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

import av
import numpy as np


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    source_hash = hashlib.sha256()
    with args.input.open('rb') as src:
        for block in iter(lambda: src.read(1024 * 1024), b''):
            source_hash.update(block)
    samples = 0
    squared = 0.0
    clipped = 0
    peak = 0
    frames = 0
    with av.open(str(args.input)) as container:
        stream = container.streams.audio[0]
        source = {'codec': stream.codec_context.name,
                  'sample_rate': stream.codec_context.sample_rate,
                  'channels': stream.codec_context.channels,
                  'container_duration_seconds': container.duration / av.time_base
                  if container.duration is not None else None}
        resampler = av.AudioResampler(format='s16', layout='mono', rate=16000)
        with (args.output / 'input.pcm').open('wb') as dst:
            def consume(frame):
                nonlocal samples, squared, clipped, peak
                data = frame.to_ndarray().reshape(-1).astype('<i2')
                dst.write(data.tobytes())
                wide = data.astype(np.float64)
                samples += data.size
                squared += float(np.dot(wide, wide))
                clipped += int(np.count_nonzero(np.abs(wide) >= 32760))
                peak = max(peak, int(np.max(np.abs(wide), initial=0)))
            for frame in container.decode(stream):
                frames += 1
                for converted in resampler.resample(frame):
                    consume(converted)
            for converted in resampler.resample(None):
                consume(converted)
    report = {'source_file': str(args.input), 'source_sha256': source_hash.hexdigest(),
              'source_bytes': args.input.stat().st_size, 'source': source,
              'decoded_frames': frames, 'decoded_seconds': samples / 16000,
              'pcm_format': 's16le/16000Hz/mono', 'pcm_bytes': samples * 2,
              'rms_dbfs': 20 * math.log10(max(math.sqrt(squared / max(samples, 1)) / 32768, 1e-12)),
              'peak_dbfs': 20 * math.log10(max(peak / 32768, 1e-12)),
              'clipped_sample_fraction': clipped / max(samples, 1),
              'cloud_transcription_run': False,
              'accuracy_status': 'Not measured: requires cloud run and human reference transcript.'}
    (args.output / 'audio_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
