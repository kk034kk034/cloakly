package com.cloakly.cloakly

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.FileInputStream

object AudioEncoder {
    fun encodeWavToM4a(inputPath: String, outputPath: String) {
        val wav = File(inputPath)
        if (!wav.exists()) {
            throw IllegalStateException("找不到 wav")
        }
        val outFile = File(outputPath)
        if (outFile.exists() && !outFile.delete()) {
            throw IllegalStateException("無法覆寫 m4a")
        }

        val sampleRate = 16000
        val channels = 1
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            sampleRate,
            channels,
        )
        format.setInteger(
            MediaFormat.KEY_AAC_PROFILE,
            MediaCodecInfo.CodecProfileLevel.AACObjectLC,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE, 48_000)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16_384)

        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var track = -1
        var muxerStarted = false
        val info = MediaCodec.BufferInfo()
        val pcmChunk = ByteArray(4096)
        var presentationUs = 0L
        var inputDone = false
        var outputDone = false

        FileInputStream(wav).use { input ->
            if (input.skip(44) < 44) {
                throw IllegalStateException("wav 檔不完整")
            }
            try {
                while (!outputDone) {
                    if (!inputDone) {
                        val inIndex = encoder.dequeueInputBuffer(10_000)
                        if (inIndex >= 0) {
                            val inBuf = encoder.getInputBuffer(inIndex)
                                ?: throw IllegalStateException("編碼器緩衝區失敗")
                            inBuf.clear()
                            val read = input.read(pcmChunk)
                            if (read <= 0) {
                                encoder.queueInputBuffer(
                                    inIndex,
                                    0,
                                    0,
                                    presentationUs,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputDone = true
                            } else {
                                val even = read - (read % 2)
                                inBuf.put(pcmChunk, 0, even)
                                encoder.queueInputBuffer(inIndex, 0, even, presentationUs, 0)
                                val frames = even / 2
                                presentationUs += frames * 1_000_000L / sampleRate
                            }
                        }
                    }

                    when (val outIndex = encoder.dequeueOutputBuffer(info, 10_000)) {
                        MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            track = muxer.addTrack(encoder.outputFormat)
                            muxer.start()
                            muxerStarted = true
                        }
                        else -> if (outIndex >= 0) {
                            val outBuf = encoder.getOutputBuffer(outIndex)
                                ?: throw IllegalStateException("編碼器輸出失敗")
                            if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                                info.size = 0
                            }
                            if (info.size > 0 && muxerStarted) {
                                outBuf.position(info.offset)
                                outBuf.limit(info.offset + info.size)
                                muxer.writeSampleData(track, outBuf, info)
                            }
                            outputDone =
                                info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            encoder.releaseOutputBuffer(outIndex, false)
                        }
                    }
                }
            } finally {
                if (muxerStarted) {
                    muxer.stop()
                }
                muxer.release()
                encoder.stop()
                encoder.release()
            }
        }
    }
}
