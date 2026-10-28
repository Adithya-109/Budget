package com.splitburn.app.capture

/** An outgoing payment read from a UPI app or bank alert. */
data class UpiPayment(
    val amountMinor: Long,
    val merchant: String,
    /** UPI ref / RRN / UTR when the alert includes one (used for de-duplication). */
    val reference: String?,
    /** `transactions.category` code. */
    val category: String,
)

/**
 * Regex parser for payment notifications from GPay, PhonePe, Paytm, BHIM and
 * bank SMS / app alerts. Pure Kotlin (no Android types) so it is unit-tested
 * on the JVM.
 *
 * Only clear, completed debits are returned. Anything that looks like money
 * coming in, a collect request, a reminder, an OTP, or a failed / pending
 * payment is ignored: logging a false expense is worse than missing one.
 */
object UpiNotificationParser {
    /** UPI and bank apps whose notifications describe the user's own payments. */
    val paymentApps: Set<String> = setOf(
        "com.google.android.apps.nbu.paisa.user", // Google Pay
        "com.phonepe.app",
        "net.one97.paytm",
        "in.org.npci.upiapp", // BHIM
        "in.amazon.mShop.android.shopping", // Amazon Pay
        "com.dreamplug.androidapp", // CRED
        "com.mobikwik_new",
        "com.snapwork.hdfc",
        "com.sbi.lotusintouch", // YONO SBI
        "com.csam.icici.bank.imobile",
        "com.axis.mobile",
        "com.msf.kbank.mobile", // Kotak
    )

    /** SMS apps: only bank-style debit alerts are accepted from these. */
    val smsApps: Set<String> = setOf(
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.android.mms",
        "com.truecaller",
    )

    fun isWatchedPackage(packageName: String): Boolean =
        packageName in paymentApps || packageName in smsApps

    private val ignoreCase = setOf(RegexOption.IGNORE_CASE)

    private val rejectPattern = Regex(
        "\\b(received|credited to your|paid you|sent you|refund(ed)?|cashback|revers(ed|al)|" +
            "fail(ed|ure)?|declined|unsuccessful|pending|requested|requesting|collect request|" +
            "reminder|is due|due on|due date|payment due|otp is|is your otp|otp for|" +
            "one[- ]time password|mandate (created|registered|set ?up)|" +
            "autopay (setup|set up|activated|registered))\\b",
        ignoreCase,
    )

    private val debitPattern = Regex(
        "\\b(debited|paid|sent|spent|payment of|payment to|paying|withdrawn|deducted|purchase|" +
            "txn of|transferred)\\b",
        ignoreCase,
    )

    private val bankAlertPattern = Regex("\\b(a/c|acct|account|upi|vpa|card)\\b", ignoreCase)

    private val currencyAmount = Regex("(?:₹|\\brs\\.?|\\binr)\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)", ignoreCase)
    private val debitedByAmount = Regex("\\bdebited\\s+(?:by|for|with)?\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)", ignoreCase)

    // Where a merchant name ends. A dot only ends it before a space, so VPAs
    // like "rapido.bike@ybl" stay whole.
    private const val STOP =
        "(?=\\s+(?:on|via|using|from|ref\\w*|upi|txn|transaction|is|has|was|at|for|a/c|ac|" +
            "successful(?:ly)?|done|completed|not)\\b|\\s*[,;:(]|\\.(?:\\s|$)|\\s*$)"

    private val merchantPatterns: List<Regex> = listOf(
        Regex("\\bto\\s+(?:vpa\\s+)?([A-Za-z0-9@._&'’ -]{2,60}?)$STOP", ignoreCase),
        Regex(";\\s*([A-Za-z0-9&'’ .-]{2,60}?)\\s+credited", ignoreCase),
        Regex("\\bupi/(?:p2[am]/)?\\d+/([A-Za-z0-9 ._&-]{2,40}?)(?=/|\\s|$)", ignoreCase),
        Regex("\\bat\\s+([A-Za-z0-9&'’ .-]{2,60}?)(?=\\s+on\\b|\\s*[.,;]|\\s*$)", ignoreCase),
    )

    private val referencePattern = Regex(
        "(?:ref(?:erence)?\\.?\\s*(?:no\\.?|number|id)?|refno|rrn|utr|upi(?:\\s*ref)?)[\\s:.#/-]*([0-9]{9,16})",
        ignoreCase,
    )

    private val whitespace = Regex("\\s+")

    const val FALLBACK_MERCHANT = "UPI payment"

    /** Returns the payment, or null if this notification is not a completed debit. */
    fun parse(packageName: String, title: String?, text: String?): UpiPayment? {
        val message = listOfNotNull(title, text)
            .filter { it.isNotBlank() }
            .joinToString(". ")
            .replace(whitespace, " ")
            .trim()
        if (message.isEmpty()) return null
        if (rejectPattern.containsMatchIn(message)) return null
        if (!debitPattern.containsMatchIn(message)) return null
        if (packageName in smsApps && !bankAlertPattern.containsMatchIn(message)) return null

        val amountMinor = extractAmount(message) ?: return null
        val merchant = extractMerchant(message)
        return UpiPayment(
            amountMinor = amountMinor,
            merchant = merchant,
            reference = referencePattern.find(message)?.groupValues?.get(1),
            category = CategoryClassifier.classify(merchant),
        )
    }

    private fun extractAmount(message: String): Long? {
        val raw = (currencyAmount.find(message) ?: debitedByAmount.find(message))
            ?.groupValues?.get(1)
            ?.replace(",", "")
            ?: return null
        val parts = raw.split('.')
        val major = parts[0].toLongOrNull() ?: return null
        val fraction = parts.getOrNull(1)?.padEnd(2, '0')?.toLongOrNull() ?: 0L
        val minor = major * 100 + fraction
        return minor.takeIf { it > 0 }
    }

    private fun extractMerchant(message: String): String {
        for (pattern in merchantPatterns) {
            val candidate = pattern.find(message)?.groupValues?.get(1)?.let(::cleanMerchant)
            if (!candidate.isNullOrEmpty()) return candidate
        }
        return FALLBACK_MERCHANT
    }

    private fun cleanMerchant(raw: String): String? {
        var name = raw.trim().trimEnd('.', '-', '_')
        if ('@' in name) {
            // A VPA like "dominos.pizza@ybl": the handle is the best name we have.
            name = name.substringBefore('@').replace(Regex("[._-]+"), " ")
        }
        name = name.replace(whitespace, " ").trim()
        if (name.length < 2 || name.all { it.isDigit() || it == ' ' }) return null
        val isAllUpper = name == name.uppercase()
        val isAllLower = name == name.lowercase()
        return if (isAllUpper || isAllLower) {
            name.lowercase().split(' ').joinToString(" ") { word -> word.replaceFirstChar { it.uppercase() } }
        } else {
            name
        }
    }
}
