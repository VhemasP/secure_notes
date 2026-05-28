package com.example.secure_notes_mvp

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Memasang FLAG_SECURE di level Engine Flutter
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.configureFlutterEngine(flutterEngine)
    }
}