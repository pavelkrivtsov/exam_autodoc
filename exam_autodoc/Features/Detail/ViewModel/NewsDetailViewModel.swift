//
//  NewsDetailViewModel.swift
//  exam_autodoc
//
//  ViewModel экрана детали: форматирование контента и проверка ссылки на статью.
//

import Foundation

@MainActor
final class NewsDetailViewModel {

    private enum Constants {
        static let metaSeparator = "  ·  "
    }

    let item: NewsItem

    init(item: NewsItem) {
        self.item = item
    }

    var title: String { item.title }
    var description: String { item.description }
    var categoryType: String { item.categoryType }
    var publishedDate: Date? { item.publishedDate }
    var imageURL: URL? { item.imageURL }

    var hasHeroImage: Bool { item.imageURL != nil }
    var hasDescription: Bool { !item.description.isEmpty }

    /// Категория и дата в одной строке мета-блока.
    var metaText: String {
        var text = item.categoryType
        if let date = item.publishedDate {
            let dateString = DateDisplay.string(from: date)
            text = text.isEmpty
                ? dateString
                : "\(text)\(Constants.metaSeparator)\(dateString)"
        }
        return text
    }

    var hasMeta: Bool { !metaText.isEmpty }

    /// URL статьи, пригодный для SFSafariViewController.
    var articleURL: URL? {
        guard let url = item.fullURL, url.isSafariCompatible else { return nil }
        return url
    }
}
