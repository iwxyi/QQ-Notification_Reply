package com.iwxyi.qqnotificationreply

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// 开机自启
/// 参考：https://blog.csdn.net/weixin_41010032/article/details/106625548
class BootCompleteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            val thisIntent = Intent(context, MainActivity::class.java)
            thisIntent.setAction("android.intent.action.MAIN")
            thisIntent.addCategory("android.intent.category.LAUNCHER")
            thisIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(thisIntent)
        }
    }
}