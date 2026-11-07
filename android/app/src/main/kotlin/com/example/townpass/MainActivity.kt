package com.example.townpass

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speechResult: MethodChannel.Result? = null
    private val speechRequest = 48152

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "townpass/speech")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                } else if (speechResult != null) {
                    result.error("busy", "語音輸入正在進行中", null)
                } else {
                    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-TW")
                        putExtra(RecognizerIntent.EXTRA_PROMPT, "請說出想詢問的內容")
                        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                    }
                    speechResult = result
                    try {
                        startActivityForResult(intent, speechRequest)
                    } catch (error: ActivityNotFoundException) {
                        speechResult = null
                        result.error("unavailable", "此裝置未安裝系統語音辨識服務", null)
                    } catch (error: Exception) {
                        speechResult = null
                        result.error("failed", "無法啟動語音輸入，請檢查系統語音服務", null)
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != speechRequest) return
        val result = speechResult ?: return
        speechResult = null
        if (resultCode == Activity.RESULT_OK) {
            result.success(data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull())
        } else {
            result.success(null) // Cancellation leaves the input unchanged.
        }
    }

    override fun onDestroy() {
        speechResult?.error("closed", "語音輸入已結束", null)
        speechResult = null
        super.onDestroy()
    }
}
