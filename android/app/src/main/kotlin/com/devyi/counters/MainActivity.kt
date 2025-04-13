package com.devyi.counters

import android.os.Bundle
import com.umeng.commonsdk.UMConfigure
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        //设置LOG开关，默认为false
        UMConfigure.setLogEnabled(true)

        //友盟预初始化
        UMConfigure.preInit(getApplicationContext(), "67c155ee9a16fe6dcd555f54", "Github")


        //友盟初始化
        UMConfigure.init(
            context, "67c155ee9a16fe6dcd555f54", "Github", UMConfigure.DEVICE_TYPE_PHONE,
            ""
        )


    }
}
