package com.seahorse.store.app

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.seahorse.app/scanner_sound"
    private var toneGenerator: ToneGenerator? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 初始化原生系统语音播报引擎 (TextToSpeech)
        try {
            textToSpeech = TextToSpeech(applicationContext, this)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playScanSuccessSound" -> {
                    try {
                        if (toneGenerator == null) {
                            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                        }
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 120)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "playImportantNoticeSound", "playOrderAlertSound" -> {
                    try {
                        // 1. 播放 Android 原生系统通知旋律
                        val notificationUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
                        val ringtone = android.media.RingtoneManager.getRingtone(applicationContext, notificationUri)
                        ringtone?.play()

                        // 2. 辅以 ToneGenerator 提示和弦
                        if (toneGenerator == null) {
                            toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
                        }
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 350)

                        // 3. 伴随触感震动反馈
                        triggerVibration()

                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                "speakText" -> {
                    val text = call.argument<String>("text")
                    if (!text.isNullOrBlank()) {
                        speakChineseText(text)
                        result.success(true)
                    } else {
                        result.error("EMPTY_TEXT", "Speech text is empty", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.seahorse.app/phone_dialer").setMethodCallHandler { call, result ->
            if (call.method == "makePhoneCall") {
                val phoneNumber = call.argument<String>("phoneNumber")
                if (!phoneNumber.isNullOrBlank()) {
                    try {
                        val intent = android.content.Intent(android.content.Intent.ACTION_DIAL, android.net.Uri.parse("tel:${phoneNumber.trim()}"))
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                } else {
                    result.error("INVALID_NUMBER", "Phone number is empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = textToSpeech?.setLanguage(Locale.CHINESE)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                textToSpeech?.setLanguage(Locale.SIMPLIFIED_CHINESE)
            }
            textToSpeech?.setSpeechRate(1.0f)
            textToSpeech?.setPitch(1.05f)
            ttsReady = true
        }
    }

    private var mediaPlayer: android.media.MediaPlayer? = null

    private fun speakChineseText(text: String) {
        if (text.isBlank()) return
        
        // 优先使用高保真中文语音流 (确保在各类Android机型上均能发出自然大声的中文报单)
        Thread {
            try {
                val encodedText = java.net.URLEncoder.encode(text.trim(), "UTF-8")
                val ttsUrl = "https://tts.baidu.com/text2audio?cuid=baike&lan=ZH&ctp=1&pdt=301&vol=15&rate=32&per=0&tex=$encodedText"
                
                runOnUiThread {
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = android.media.MediaPlayer().apply {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                val audioAttributes = android.media.AudioAttributes.Builder()
                                    .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                                    .build()
                                setAudioAttributes(audioAttributes)
                            } else {
                                @Suppress("DEPRECATION")
                                setAudioStreamType(AudioManager.STREAM_NOTIFICATION)
                            }
                            setDataSource(ttsUrl)
                            setOnPreparedListener { mp ->
                                mp.start()
                            }
                            setOnErrorListener { _, _, _ ->
                                fallbackToLocalTts(text)
                                true
                            }
                            prepareAsync()
                        }
                    } catch (e: Exception) {
                        fallbackToLocalTts(text)
                    }
                }
            } catch (e: Exception) {
                fallbackToLocalTts(text)
            }
        }.start()
    }

    private fun fallbackToLocalTts(text: String) {
        runOnUiThread {
            try {
                if (textToSpeech == null) {
                    textToSpeech = TextToSpeech(applicationContext) { status ->
                        if (status == TextToSpeech.SUCCESS) {
                            textToSpeech?.language = Locale.CHINESE
                            ttsReady = true
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "SEAHORSE_TTS_${System.currentTimeMillis()}")
                            } else {
                                @Suppress("DEPRECATION")
                                textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null)
                            }
                        }
                    }
                } else {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "SEAHORSE_TTS_${System.currentTimeMillis()}")
                    } else {
                        @Suppress("DEPRECATION")
                        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun triggerVibration() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 300, 200, 350), -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 300, 200, 350), -1)
            }
        } catch (e: Exception) {
            // ignore
        }
    }

    override fun onDestroy() {
        try {
            textToSpeech?.stop()
            textToSpeech?.shutdown()
            textToSpeech = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
