package com.muslimazkar.muslim_azkar

import android.content.Intent
import android.content.ClipData
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.muslimazkar/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "timezone" -> result.success(TimeZone.getDefault().id)
                    "shareDirectory" -> {
                        try {
                            val directory = File(cacheDir, "azkar_share").apply { mkdirs() }
                            // Shared files stay available for recipients; expire old export sessions.
                            directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 172800000L }
                                ?.forEach { it.deleteRecursively() }
                            result.success(directory.absolutePath)
                        } catch (e: Exception) {
                            result.error("CACHE_FAILED", e.message, null)
                        }
                    }
                    "shareImages" -> {
                        try {
                            val paths = call.arguments as? List<*>
                                ?: throw IllegalArgumentException("Missing images")
                            require(paths.isNotEmpty())
                            val root = File(cacheDir, "azkar_share").canonicalFile
                            val uris = ArrayList(paths.map { path ->
                                val file = File(path as String).canonicalFile
                                require(file.path.startsWith(root.path + File.separator) && file.isFile && file.extension == "png")
                                FileProvider.getUriForFile(this, "$packageName.share", file)
                            })
                            val intent = Intent(if (uris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE).apply {
                                type = "image/png"
                                if (uris.size == 1) putExtra(Intent.EXTRA_STREAM, uris.first())
                                else putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                clipData = ClipData.newUri(contentResolver, "أذكار المسلم", uris.first()).apply {
                                    uris.drop(1).forEach { addItem(ClipData.Item(it)) }
                                }
                            }
                            startActivity(Intent.createChooser(intent, "مشاركة صورة الذكر"))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("IMAGE_SHARE_FAILED", e.message, null)
                        }
                    }
                    "share" -> {
                        val text = call.arguments as? String
                        if (text == null) {
                            result.error("INVALID_TEXT", "Missing text", null)
                        } else {
                            try {
                                val intent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, text)
                                }
                                startActivity(Intent.createChooser(intent, "مشاركة الذكر"))
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("SHARE_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
