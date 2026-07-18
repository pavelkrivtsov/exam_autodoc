//
//  News.swift
//  exam_autodoc
//
//  Модели данных новостной ленты Autodoc.
//

import Foundation

/// Одна страница ответа пагинированного API `/api/news/{page}/{pageSize}`.
nonisolated struct NewsPage: Decodable, Sendable {
    let news: [NewsItem]
    let totalCount: Int
}

/// Одна новость.
///
/// Соответствие `Identifiable`/`Hashable` строится только по `id`,
/// чтобы элемент можно было использовать как идентификатор DiffableDataSource
/// без коллизий, когда отличаются лишь декоративные поля.
nonisolated struct NewsItem: Decodable, Sendable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: Date?
    let fullURL: URL?
    let imageURL: URL?
    let categoryType: String

    private enum CodingKeys: String, CodingKey {
        case id, title, description
        case publishedDate
        case fullURL = "fullUrl"
        case imageURL = "titleImageUrl"
        case categoryType
    }

    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension NewsItem {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        categoryType = (try? container.decode(String.self, forKey: .categoryType)) ?? ""
        fullURL = (try? container.decode(String.self, forKey: .fullURL)).flatMap(URL.init(string:))
        imageURL = (try? container.decode(String.self, forKey: .imageURL)).flatMap(URL.init(string:))

        if let raw = try? container.decode(String.self, forKey: .publishedDate) {
            publishedDate = DateParsing.date(from: raw)
        } else {
            publishedDate = nil
        }
    }
}

/// API отдаёт даты без часового пояса (например `2026-07-11T00:00:00`),
/// которые `ISO8601DateFormatter` отклоняет — поэтому свой парсер.
private enum DateParsing {
    nonisolated static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    nonisolated static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}
