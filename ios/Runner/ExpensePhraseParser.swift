import Foundation

/// Swift port of `lib/domain/expense_phrase_parser.dart` and
/// `lib/domain/category_classifier.dart`. Both must produce identical results
/// for `test/fixtures/expense_phrases.json` (checked by RunnerTests).
struct ParsedExpense: Equatable {
    let amountMinor: Int64
    let merchant: String
    /// Everyone on the bill except the user, in mention order (includes payer).
    let friends: [String]
    /// The friend who paid, or nil when the user paid.
    let payer: String?
    /// `transactions.category` code.
    let category: String
}

enum CategoryClassifier {
    static let other = "Other"

    /// Same order and contents as the Dart `CategoryClassifier.keywords`.
    static let keywords: [(category: String, words: [String])] = [
        ("Food", [
            "food", "lunch", "dinner", "breakfast", "brunch", "snack", "meal",
            "pizza", "burger", "biryani", "coffee", "chai", "tea", "cafe",
            "canteen", "mess", "restaurant", "dhaba", "domino", "swiggy", "zomato",
            "starbucks", "mcdonald", "mcd", "kfc", "subway", "juice", "icecream",
            "dessert", "bakery", "momo", "maggi", "thali", "dosa", "sandwich",
            "shawarma", "roll", "chaayos", "eatery",
        ]),
        ("Groceries", [
            "grocery", "groceries", "blinkit", "zepto", "instamart", "bigbasket",
            "dmart", "kirana", "vegetable", "veggies", "fruit", "milk", "eggs",
            "supermarket", "jiomart",
        ]),
        ("Transit", [
            "uber", "ola", "rapido", "auto", "cab", "taxi", "metro", "bus", "train",
            "irctc", "petrol", "diesel", "fuel", "parking", "toll", "flight",
            "indigo", "redbus", "rickshaw",
        ]),
        ("Utilities", [
            "wifi", "internet", "broadband", "electricity", "electric", "rent",
            "recharge", "airtel", "jio", "vodafone", "bsnl", "gas", "maid", "cook",
            "laundry",
        ]),
        ("Fun", [
            "movie", "cinema", "pvr", "inox", "netflix", "spotify", "prime",
            "hotstar", "bookmyshow", "concert", "party", "game", "gaming",
            "bowling", "club", "pub", "bar", "beer", "drinks", "trip", "outing",
            "steam",
        ]),
    ]

    static func classify<S: Sequence>(words: S) -> String where S.Element == String {
        for word in words {
            let normalized = word.lowercased()
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "’", with: "")
                .replacingOccurrences(of: "-", with: "")
            if normalized.isEmpty { continue }
            for (category, list) in keywords {
                for keyword in list
                where normalized == keyword || (keyword.count >= 4 && normalized.hasPrefix(keyword)) {
                    return category
                }
            }
        }
        return other
    }
}

enum ExpensePhraseParser {
    static let fallbackMerchant = "Quick expense"

    private static let amountPattern = try! NSRegularExpression(
        pattern: #"(?<![\w.,])(₹|rs\.?|inr|\$|usd)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:\.(\d{1,2}))?(k\b)?(?:\s*(rs\.?|rupees?|bucks|inr|dollars?))?(?!\w)"#,
        options: [.caseInsensitive])

    private static let tokenPattern = try! NSRegularExpression(
        pattern: #"[\p{L}\p{N}'’&@._-]+|[,&+]"#)

    private static let edgePunctuation = try! NSRegularExpression(pattern: #"^[._-]+|[._-]+$"#)

    private static let fillers: Set<String> = [
        "spent", "spend", "spending", "paid", "pay", "paying", "bought", "buy",
        "got", "log", "logged", "add", "added", "split", "splitting", "just",
        "total", "i", "me", "myself", "us", "we", "rs", "rupees", "bucks",
    ]
    private static let friendIntroducers: Set<String> = ["with", "between", "among", "amongst"]
    private static let itemIntroducers: Set<String> = ["on", "for"]
    private static let placeIntroducers: Set<String> = ["at", "from", "to", "in"]
    private static let separators: Set<String> = ["and", "&", "+", ","]
    private static let selfWords: Set<String> = ["me", "myself", "i", "us"]
    private static let articles: Set<String> = ["a", "an", "the", "some"]

    private enum Mode { case item, place, friends, payer }

    /// Returns nil when the phrase has no amount.
    static func parse(_ phrase: String) -> ParsedExpense? {
        let ns = phrase as NSString
        guard let amount = extractAmount(ns) else { return nil }
        let rest = ns.replacingCharacters(in: amount.range, with: " ") as NSString

        var tokens: [String] = []
        for match in tokenPattern.matches(in: rest as String, range: NSRange(location: 0, length: rest.length)) {
            let token = clean(rest.substring(with: match.range))
            if !token.isEmpty { tokens.append(token) }
        }
        let lower = tokens.map { $0.lowercased() }

        var friends: [String] = []
        var payer: String?
        func addFriend(_ raw: String) {
            let name = normalizeName(raw)
            if !friends.contains(where: { $0.lowercased() == name.lowercased() }) {
                friends.append(name)
            }
        }

        var start = 0
        if tokens.count >= 2, lower[1] == "paid",
           tokens.count < 3 || lower[2] != "by",
           isNameCandidate(lower[0]) {
            payer = normalizeName(tokens[0])
            addFriend(tokens[0])
            start = 2
        }

        var item: [String] = []
        var place: [String] = []
        var mode = Mode.item
        var i = start
        while i < tokens.count {
            defer { i += 1 }
            let word = lower[i]
            if word == "paid", i + 1 < tokens.count, lower[i + 1] == "by" {
                mode = .payer
                i += 1
                continue
            }
            if friendIntroducers.contains(word) { mode = .friends; continue }
            if word == "for", i + 1 < tokens.count, selfWords.contains(lower[i + 1]) {
                mode = .friends
                continue
            }
            if itemIntroducers.contains(word) { mode = .item; continue }
            if placeIntroducers.contains(word) { mode = .place; continue }
            switch mode {
            case .friends:
                if separators.contains(word) || selfWords.contains(word) || articles.contains(word) {
                    continue
                }
                addFriend(tokens[i])
            case .payer:
                if separators.contains(word) || !isNameCandidate(word) { continue }
                payer = normalizeName(tokens[i])
                addFriend(tokens[i])
                mode = .item
            case .item, .place:
                if fillers.contains(word) || separators.contains(word) { continue }
                if mode == .item { item.append(tokens[i]) } else { place.append(tokens[i]) }
            }
        }

        return ParsedExpense(
            amountMinor: amount.minor,
            merchant: merchant(from: place.isEmpty ? item : place),
            friends: friends,
            payer: payer,
            category: CategoryClassifier.classify(words: item + place))
    }

    /// Splits a Shortcuts "Friends" field: commas, "and", "&", "+".
    static func friendNames(fromCSV csv: String) -> [String] {
        var names: [String] = []
        let ns = csv as NSString
        for match in tokenPattern.matches(in: csv, range: NSRange(location: 0, length: ns.length)) {
            let token = clean(ns.substring(with: match.range))
            let lowered = token.lowercased()
            if token.isEmpty || separators.contains(lowered) || selfWords.contains(lowered) { continue }
            let name = normalizeName(token)
            if !names.contains(where: { $0.lowercased() == name.lowercased() }) {
                names.append(name)
            }
        }
        return names
    }

    static func normalizeName(_ raw: String) -> String {
        let lowered = raw.lowercased()
        let isAllLower = raw == lowered
        let isAllUpper = raw.count > 1 && raw == raw.uppercased()
        if !isAllLower && !isAllUpper { return raw }
        return lowered.prefix(1).uppercased() + lowered.dropFirst()
    }

    private static func extractAmount(_ phrase: NSString) -> (minor: Int64, range: NSRange)? {
        var marked: (minor: Int64, range: NSRange)?
        var largest: (minor: Int64, range: NSRange)?
        let matches = amountPattern.matches(
            in: phrase as String, range: NSRange(location: 0, length: phrase.length))
        for match in matches {
            let integerText = phrase.substring(with: match.range(at: 2))
                .replacingOccurrences(of: ",", with: "")
            guard let integer = Int64(integerText), integer <= 9_999_999_999 else { continue }
            let fractionRange = match.range(at: 3)
            let fractionText = fractionRange.location == NSNotFound ? "" : phrase.substring(with: fractionRange)
            let fraction = Int64(fractionText.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0
            var minor = integer * 100 + fraction
            if match.range(at: 4).location != NSNotFound { minor *= 1000 }
            let amount = (minor: minor, range: match.range)
            if match.range(at: 1).location != NSNotFound || match.range(at: 5).location != NSNotFound {
                if marked == nil { marked = amount }
            } else if largest == nil || minor > largest!.minor {
                largest = amount
            }
        }
        guard let chosen = marked ?? largest, chosen.minor > 0 else { return nil }
        return chosen
    }

    private static func isNameCandidate(_ lowerWord: String) -> Bool {
        !fillers.contains(lowerWord) && !selfWords.contains(lowerWord)
            && !separators.contains(lowerWord) && !articles.contains(lowerWord)
            && !friendIntroducers.contains(lowerWord) && !itemIntroducers.contains(lowerWord)
            && !placeIntroducers.contains(lowerWord)
            && CategoryClassifier.classify(words: [lowerWord]) == CategoryClassifier.other
    }

    private static func clean(_ token: String) -> String {
        let ns = token as NSString
        return edgePunctuation.stringByReplacingMatches(
            in: token, range: NSRange(location: 0, length: ns.length), withTemplate: "")
    }

    private static func merchant(from words: [String]) -> String {
        var trimmed = words
        while let first = trimmed.first, articles.contains(first.lowercased()) {
            trimmed.removeFirst()
        }
        if trimmed.isEmpty { return fallbackMerchant }
        let text = trimmed.joined(separator: " ")
        if text != text.lowercased() { return text }
        return trimmed.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}
