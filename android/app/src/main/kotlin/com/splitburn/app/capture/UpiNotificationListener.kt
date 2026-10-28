package com.splitburn.app.capture

import android.app.Notification
import android.content.Context
import android.database.SQLException
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Turns UPI / bank payment notifications into ledger entries while the app is
 * closed. Reads only the packages in [UpiNotificationParser]; everything else
 * is dropped before its text is touched.
 *
 * Declared with `android:process=":capture"` so its SQLite connection lives in
 * a different process from Flutter's (see [FinanceStore]).
 */
class UpiNotificationListener : NotificationListenerService() {
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!UpiNotificationParser.isWatchedPackage(sbn.packageName)) return
        val notification = sbn.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
        val payment = UpiNotificationParser.parse(sbn.packageName, title, text) ?: return
        val postedAt = sbn.postTime

        worker.execute { record(payment, postedAt) }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }

    private fun record(payment: UpiPayment, postedAtMillis: Long) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val seen = prefs.getString(KEY_REFERENCES, "").orEmpty()
            .split('\n')
            .filter { it.isNotEmpty() }
        if (payment.reference != null && payment.reference in seen) return

        try {
            val logged = FinanceStore(this).logAutoCapturedPayment(payment, postedAtMillis)
            Log.i(TAG, if (logged) "Logged ${payment.amountMinor} at ${payment.merchant}" else "Skipped duplicate")
        } catch (e: SQLException) {
            Log.w(TAG, "Could not log captured payment", e)
            return
        }

        payment.reference?.let { reference ->
            val updated = (seen + reference).takeLast(MAX_REMEMBERED_REFERENCES)
            prefs.edit().putString(KEY_REFERENCES, updated.joinToString("\n")).apply()
        }
    }

    private companion object {
        const val TAG = "SplitBurnCapture"
        const val PREFS = "upi_capture"
        const val KEY_REFERENCES = "seen_references"
        const val MAX_REMEMBERED_REFERENCES = 200
    }
}
