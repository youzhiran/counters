package com.devyi.counters

import android.os.Bundle
import android.content.Context
// 友盟SDK导入已注释 - 友盟功能已禁用
// import com.umeng.commonsdk.UMConfigure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 友盟MethodChannel已注释 - 友盟功能已禁用
    // private val CHANNEL = "com.devyi.counters/umeng"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 友盟MethodChannel处理已注释 - 友盟功能已禁用
        /*
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initUmeng" -> {
                    UMConfigure.init(
                        this, "67c155ee9a16fe6dcd555f54", "Github", UMConfigure.DEVICE_TYPE_PHONE,
                        ""
                    )
                    result.success(true)
                }
            }
        }
        */
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 友盟初始化已注释 - 友盟功能已禁用
        // UMConfigure.setLogEnabled(true)
        // UMConfigure.preInit(applicationContext, "67c155ee9a16fe6dcd555f54", "Github")
    }
}