//
//  NewsService.swift
//  exam_autodoc
//
//  Сетевой слой новостной ленты Autodoc. Чистый async/await через URLSession,
//  без сторонних зависимостей.
//

import Foundation

enum NewsServiceError: LocalizedError {
    case invalidResponse
    case server(status: Int)
    case decoding(any Error)
    case transport(any Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Получен некорректный ответ сервера."

        case .server(let status):
            return "Сервер вернул ошибку (\(status))."

        case .decoding:
            return "Не удалось обработать данные новостей."

        case .transport(let error):
            return (error as? URLError)?.localizedDescription ?? error.localizedDescription
        }
    }
}

/// Абстракция сервиса: ViewModel можно тестировать со стабом.
protocol NewsServing: Sendable {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage
}

/// Формирует URL страниц. Нумерация страниц с 1, как в API.
enum NewsEndpoint {
    static let baseURL = URL(string: "https://webapi.autodoc.ru/api/news")!

    static func page(_ page: Int, pageSize: Int) -> URL {
        baseURL.appending(path: "\(page)/\(pageSize)")
    }
}

final class NewsService: NewsServing {
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(session: URLSession = NewsService.makeSession()) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage {
        let url = NewsEndpoint.page(page, pageSize: pageSize)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NewsServiceError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NewsServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NewsServiceError.server(status: http.statusCode)
        }

        do {
            return try decoder.decode(NewsPage.self, from: data)
        } catch {
            throw NewsServiceError.decoding(error)
        }
    }

    nonisolated private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: 128 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }
}
