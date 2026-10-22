package com.longwallet

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "LongWalletListener"
        
        // Callback to send intercepted notification to MainActivity
        var onNotificationReceived: ((Map<String, Any?>) -> Unit)? = null

        // Supported Vietnamese Banking & E-wallet package names
        val SUPPORTED_BANK_PACKAGES = setOf(
            "com.VCB",                    // Vietcombank
            "com.mbmobile",               // MB Bank
            "vn.com.techcombank.bb.app",   // Techcombank
            "com.vnpay.bidv",             // BIDV SmartBanking
            "com.vietinbank.ipay",         // VietinBank iPay
            "com.msb.mb.activity",        // MSB mBank
            "com.tpb.mb.gprsandroid",     // TPBank Mobile
            "com.acb.dcenter",            // ACB ONE
            "com.vng.zingpay",            // ZaloPay
            "com.mservice.momotransfer"    // MoMo
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        
        // Log all banking notifications
        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val message = if (bigText.isNotEmpty()) bigText else text

        if (title.isEmpty() && message.isEmpty()) return

        // Check if package is from a supported bank or has banking money patterns
        val isBankPackage = SUPPORTED_BANK_PACKAGES.contains(packageName)
        val hasMoneyIndicator = message.contains("VND", ignoreCase = true) || 
                                message.contains("GD:", ignoreCase = true) ||
                                message.contains("so du", ignoreCase = true) ||
                                message.contains("sodu", ignoreCase = true) ||
                                message.contains("bien dong", ignoreCase = true)

        if (isBankPackage || hasMoneyIndicator) {
            Log.d(TAG, "Banking notification captured: $packageName | Title: $title | Msg: $message")
            
            val payload = mapOf(
                "packageName" to packageName,
                "title" to title,
                "message" to message,
                "timestamp" to sbn.postTime
            )

            // Emit to Flutter runtime if active
            onNotificationReceived?.invoke(payload)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
