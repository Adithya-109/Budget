package com.splitburn.app.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class UpiNotificationParserTest {
    private val gpay = "com.google.android.apps.nbu.paisa.user"
    private val phonePe = "com.phonepe.app"
    private val paytm = "net.one97.paytm"
    private val sms = "com.google.android.apps.messaging"

    private fun parse(pkg: String, title: String?, text: String?) =
        UpiNotificationParser.parse(pkg, title, text)

    @Test
    fun googlePayDebit() {
        val p = parse(gpay, "₹450 paid to Domino's Pizza", "Paid with HDFC Bank ••1234")!!
        assertEquals(45000L, p.amountMinor)
        assertEquals("Domino's Pizza", p.merchant)
        assertEquals("Food", p.category)
    }

    @Test
    fun phonePeDebitWithDecimals() {
        val p = parse(phonePe, "Paid ₹1,249.50 to Blinkit", "Payment successful")!!
        assertEquals(124950L, p.amountMinor)
        assertEquals("Blinkit", p.merchant)
        assertEquals("Groceries", p.category)
    }

    @Test
    fun paytmRupeeAbbreviation() {
        val p = parse(paytm, "Paid Rs.230 to Uber India", null)!!
        assertEquals(23000L, p.amountMinor)
        assertEquals("Uber India", p.merchant)
        assertEquals("Transit", p.category)
    }

    @Test
    fun hdfcSmsWithReference() {
        val p = parse(
            sms, "AX-HDFCBK",
            "Sent Rs.450.00 From HDFC Bank A/C *1234 To DOMINOS PIZZA On 28/10/26 Ref 429812345678 Not You? Call 18002586161",
        )!!
        assertEquals(45000L, p.amountMinor)
        assertEquals("Dominos Pizza", p.merchant)
        assertEquals("429812345678", p.reference)
    }

    @Test
    fun sbiSmsDebitedByAmountAndVpa() {
        val p = parse(
            sms, "VM-SBIUPI",
            "Dear UPI user A/C X1234 debited by 120.0 on date 28Oct26 trf to rapido.bike@ybl Refno 429812345679. If not u? call 1800111109. -SBI",
        )!!
        assertEquals(12000L, p.amountMinor)
        assertEquals("Rapido Bike", p.merchant)
        assertEquals("429812345679", p.reference)
        assertEquals("Transit", p.category)
    }

    @Test
    fun iciciCreditedMerchantStyle() {
        val p = parse(
            sms, "JD-ICICIB",
            "ICICI Bank Acct XX123 debited for Rs 399.00 on 28-Oct-26; NETFLIX credited. UPI:429812345680. Call 18002662 for dispute.",
        )!!
        assertEquals(39900L, p.amountMinor)
        assertEquals("Netflix", p.merchant)
        assertEquals("429812345680", p.reference)
        assertEquals("Fun", p.category)
    }

    @Test
    fun axisUpiInfoPath() {
        val p = parse(
            sms, "AD-AXISBK",
            "INR 80.00 debited A/c no. XX1234 28-10-26 UPI/P2M/429812345681/CHAAYOS Not you? SMS BLOCKUPI",
        )!!
        assertEquals(8000L, p.amountMinor)
        assertEquals("Chaayos", p.merchant)
        assertEquals("Food", p.category)
    }

    @Test
    fun autopayDebitIsKept() {
        val p = parse(sms, "VK-KOTAKB", "Rs 199 debited from Kotak A/c X1234 for Spotify autopay. Never share OTP with anyone.")!!
        assertEquals(19900L, p.amountMinor)
    }

    @Test
    fun ignoresMoneyComingIn() {
        assertNull(parse(gpay, "Rahul paid you ₹200", "Tap to view"))
        assertNull(parse(phonePe, "Received ₹300 from Priya", null))
        assertNull(parse(sms, "AX-HDFCBK", "Rs.500.00 credited to your A/c XX1234 by VPA rahul@okaxis"))
        assertNull(parse(gpay, "Refund of ₹450 from Domino's processed", null))
    }

    @Test
    fun ignoresRequestsFailuresAndOtps() {
        assertNull(parse(gpay, "Aman requested ₹150", "Pay or decline"))
        assertNull(parse(phonePe, "Payment of ₹450 to Domino's failed", null))
        assertNull(parse(paytm, "Payment pending", "₹99 to Netflix is pending"))
        assertNull(parse(sms, "AX-HDFCBK", "123456 is your OTP for payment of Rs 450 at Dominos. Do not share."))
    }

    @Test
    fun ignoresChatsAndUnwatchedApps() {
        assertNull(parse(sms, "Mom", "Paid the electricity guy 500 today"))
        assertEquals(false, UpiNotificationParser.isWatchedPackage("com.whatsapp"))
    }

    @Test
    fun fallsBackWhenNoMerchant() {
        val p = parse(gpay, "₹75 paid", "Payment successful")!!
        assertEquals(UpiNotificationParser.FALLBACK_MERCHANT, p.merchant)
        assertEquals("Other", p.category)
    }
}
