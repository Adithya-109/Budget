package com.splitburn.app.capture

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.UUID

/**
 * Writes auto-captured payments into the shared `finance.sqlite`, following
 * the write contract in CLAUDE.md §6.
 *
 * Runs in the `:capture` process (see AndroidManifest.xml). Flutter's Dart
 * code links its own SQLite build, and two SQLite copies inside one process
 * break POSIX advisory locks; separate processes lock correctly through WAL.
 */
internal class FinanceStore(private val context: Context) {
    companion object {
        const val DATABASE_FILE = "finance.sqlite"
        const val SOURCE = "ANDROID_UPI_AUTO"

        /**
         * GPay and the bank's SMS usually both announce one payment within
         * seconds. Same amount within this window counts as a duplicate.
         */
        const val DUPLICATE_WINDOW_SECONDS = 180L
    }

    /** Same path Dart resolves with `getApplicationSupportDirectory()`. */
    val databaseFile: File get() = File(context.filesDir, DATABASE_FILE)

    /**
     * Logs [payment] as a solo expense the user paid (`my_share = total_paid`,
     * bank balance reduced). Returns false when it was a duplicate.
     */
    fun logAutoCapturedPayment(payment: UpiPayment, postedAtMillis: Long): Boolean {
        val db = open()
        try {
            db.beginTransaction()
            try {
                val createdAt = postedAtMillis / 1000
                val logged = if (isDuplicate(db, payment.amountMinor, createdAt)) {
                    false
                } else {
                    insert(db, payment, createdAt)
                    true
                }
                db.setTransactionSuccessful()
                return logged
            } finally {
                db.endTransaction()
            }
        } finally {
            db.close()
        }
    }

    private fun open(): SQLiteDatabase {
        val db = SQLiteDatabase.openDatabase(
            databaseFile.path,
            null,
            SQLiteDatabase.OPEN_READWRITE or
                SQLiteDatabase.CREATE_IF_NECESSARY or
                // Don't add Android's android_metadata table to the shared schema.
                SQLiteDatabase.NO_LOCALIZED_COLLATORS or
                // Android manages journal_mode itself; this keeps the file in WAL.
                SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING,
        )
        try {
            db.rawQuery("PRAGMA busy_timeout = 5000", null).use { it.moveToFirst() }
            db.setForeignKeyConstraintsEnabled(true)
            ensureSchema(db)
        } catch (e: Exception) {
            db.close()
            throw e
        }
        return db
    }

    /** Idempotent; `user_version` is left to Drift. */
    private fun ensureSchema(db: SQLiteDatabase) {
        db.beginTransaction()
        try {
            FinanceSchema.statements.forEach(db::execSQL)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    private fun isDuplicate(db: SQLiteDatabase, amountMinor: Long, createdAt: Long): Boolean {
        db.rawQuery(
            "SELECT COUNT(*) FROM transactions WHERE source = ? AND ABS(total_paid - ?) < 0.005 " +
                "AND created_at BETWEEN ? AND ?",
            arrayOf(
                SOURCE,
                toMajor(amountMinor).toString(),
                (createdAt - DUPLICATE_WINDOW_SECONDS).toString(),
                (createdAt + DUPLICATE_WINDOW_SECONDS).toString(),
            ),
        ).use { cursor ->
            return cursor.moveToFirst() && cursor.getLong(0) > 0
        }
    }

    private fun insert(db: SQLiteDatabase, payment: UpiPayment, createdAt: Long) {
        val amount = toMajor(payment.amountMinor)
        db.insertOrThrow(
            "transactions",
            null,
            ContentValues().apply {
                put("id", UUID.randomUUID().toString())
                put("merchant", payment.merchant)
                put("total_paid", amount)
                put("my_share", amount)
                put("category", payment.category)
                put("paid_by_me", 1)
                put("source", SOURCE)
                putNull("receipt_image_path")
                put("created_at", createdAt)
            },
        )
        db.execSQL(
            "UPDATE budget_config SET current_bank_balance = ROUND(current_bank_balance + ?, 2) WHERE id = 1",
            arrayOf<Any>(-amount),
        )
    }

    private fun toMajor(minor: Long): Double = minor / 100.0
}
