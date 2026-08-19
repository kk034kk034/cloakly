package com.cloakly.cloakly

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cloakly/files")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType") ?: "audio/mp4"
                if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("bad_args", "缺少檔案路徑", null)
                    return@setMethodCallHandler
                }
                try {
                    result.success(saveToDownloads(sourcePath, fileName, mimeType))
                } catch (error: Exception) {
                    result.error("save_failed", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cloakly/recording_keep_alive")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        requestNotificationPermission()
                        RecordingKeepAliveService.start(this)
                        result.success(true)
                    }
                    "stop" -> {
                        RecordingKeepAliveService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cloakly/audio_encode")
            .setMethodCallHandler { call, result ->
                if (call.method != "encodeWavToM4a") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                if (inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                    result.error("bad_args", "缺少路徑", null)
                    return@setMethodCallHandler
                }
                Thread {
                    try {
                        AudioEncoder.encodeWavToM4a(inputPath, outputPath)
                        runOnUiThread { result.success(outputPath) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error("encode_failed", error.message, null)
                        }
                    }
                }.start()
            }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2001)
    }

    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String,
    ): String {
        val source = File(sourcePath)
        if (!source.exists()) {
            throw IllegalStateException("找不到錄音檔")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/Cloakly",
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                values,
            ) ?: throw IllegalStateException("無法寫入下載資料夾")
            contentResolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("無法寫入下載資料夾")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return "Download/Cloakly/$fileName"
        }

        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "Cloakly",
        )
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("無法建立下載資料夾")
        }
        val dest = File(dir, fileName)
        source.copyTo(dest, overwrite = true)
        return dest.absolutePath
    }
}
