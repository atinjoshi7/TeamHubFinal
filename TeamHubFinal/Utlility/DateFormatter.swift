//
//  DateFormatter.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 06/04/26.
//

import Foundation
enum DateUtils {

    // MARK: - Formatters (cached for performance)

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let yyyyMMddFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: - Parse (String → Date)

    static func parse(_ string: String?) -> Date? {
        guard let string = string else { return nil }

        // Try ISO8601 first
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Fallback to yyyy-MM-dd
        if let date = yyyyMMddFormatter.date(from: string) {
            return date
        }

        return nil
    }

    // MARK: - Format (Date → String)

    static func toYYYYMMDD(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        return yyyyMMddFormatter.string(from: date)
    }

    static func toISO8601(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        return isoFormatter.string(from: date)
    }
}
