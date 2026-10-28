package com.splitburn.app.capture

import org.junit.Assert.assertEquals
import org.junit.Test

/** Same expectations as the classifier test in test/domain/expense_phrase_parser_test.dart. */
class CategoryClassifierTest {
    @Test
    fun matchesTheDartRules() {
        assertEquals("Food", CategoryClassifier.classify("Domino's Pizza"))
        assertEquals("Other", CategoryClassifier.classify("Olamide"))
        assertEquals("Transit", CategoryClassifier.classify("Ola cab"))
        assertEquals("Utilities", CategoryClassifier.classify("Wi-Fi"))
        assertEquals("Groceries", CategoryClassifier.classify("1.2k groceries at blinkit"))
        assertEquals("Fun", CategoryClassifier.classify("movie tickets"))
    }
}
