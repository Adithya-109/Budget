package com.splitburn.app.capture

/**
 * Kotlin copy of `lib/domain/category_classifier.dart`: same keyword lists,
 * same order, same rule (lowercase, strip apostrophes and hyphens, exact match
 * or prefix match for keywords of 4+ letters, first matching word wins).
 */
internal object CategoryClassifier {
    const val OTHER = "Other"

    private val keywords: List<Pair<String, List<String>>> = listOf(
        "Food" to listOf(
            "food", "lunch", "dinner", "breakfast", "brunch", "snack", "meal",
            "pizza", "burger", "biryani", "coffee", "chai", "tea", "cafe",
            "canteen", "mess", "restaurant", "dhaba", "domino", "swiggy", "zomato",
            "starbucks", "mcdonald", "mcd", "kfc", "subway", "juice", "icecream",
            "dessert", "bakery", "momo", "maggi", "thali", "dosa", "sandwich",
            "shawarma", "roll", "chaayos", "eatery",
        ),
        "Groceries" to listOf(
            "grocery", "groceries", "blinkit", "zepto", "instamart", "bigbasket",
            "dmart", "kirana", "vegetable", "veggies", "fruit", "milk", "eggs",
            "supermarket", "jiomart",
        ),
        "Transit" to listOf(
            "uber", "ola", "rapido", "auto", "cab", "taxi", "metro", "bus", "train",
            "irctc", "petrol", "diesel", "fuel", "parking", "toll", "flight",
            "indigo", "redbus", "rickshaw",
        ),
        "Utilities" to listOf(
            "wifi", "internet", "broadband", "electricity", "electric", "rent",
            "recharge", "airtel", "jio", "vodafone", "bsnl", "gas", "maid", "cook",
            "laundry",
        ),
        "Fun" to listOf(
            "movie", "cinema", "pvr", "inox", "netflix", "spotify", "prime",
            "hotstar", "bookmyshow", "concert", "party", "game", "gaming",
            "bowling", "club", "pub", "bar", "beer", "drinks", "trip", "outing",
            "steam",
        ),
    )

    private val wordPattern = Regex("[\\p{L}\\p{N}'’-]+")
    private val stripPattern = Regex("['’-]")

    fun classifyWords(words: Iterable<String>): String {
        for (word in words) {
            val normalized = word.lowercase().replace(stripPattern, "")
            if (normalized.isEmpty()) continue
            for ((category, list) in keywords) {
                if (list.any { normalized == it || (it.length >= 4 && normalized.startsWith(it)) }) {
                    return category
                }
            }
        }
        return OTHER
    }

    fun classify(text: String): String = classifyWords(wordPattern.findAll(text).map { it.value }.asIterable())
}
