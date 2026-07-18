//
//  DateDisplay.swift
//  exam_autodoc
//
//  Общий кэшируемый форматтер дат публикации на русском языке.
//

import Foundation

enum DateDisplay {
    nonisolated private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter
    }()

    nonisolated static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
