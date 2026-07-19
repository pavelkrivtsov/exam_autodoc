//
//  NewsService.swift
//  exam_autodoc
//
//  Сетевой слой новостной ленты Autodoc. Чистый async/await через URLSession,
//  без сторонних зависимостей.
//

import Foundation

nonisolated private enum Constants {
    /// HTTP-заголовки запроса новостей.
    enum Header {
        /// Имя заголовка Accept - сервер отдаёт JSON, а не HTML.
        static let acceptField = "Accept"
        /// Значение Accept - явно просим application/json.
        static let acceptJSON = "application/json"
    }

    /// Размеры URLCache для сессии NewsService.
    enum Cache {
        /// Память URLCache - быстрее повторные ответы без сети.
        static let memoryCapacity = 16 * 1024 * 1024
        /// Диск URLCache - переживает перезапуск приложения.
        static let diskCapacity = 128 * 1024 * 1024
    }

    /// Диапазон успешных HTTP-кодов - всё остальное считаем ошибкой сервера.
    static let successStatusCodes = 200..<300
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
        request.setValue(Constants.Header.acceptJSON, forHTTPHeaderField: Constants.Header.acceptField)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logFailure("транспорт", url: url, detail: error.localizedDescription)
            throw NewsServiceError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            logFailure("некорректный ответ", url: url)
            throw NewsServiceError.invalidResponse
        }
        guard Constants.successStatusCodes.contains(http.statusCode) else {
            logFailure("HTTP \(http.statusCode)", url: url, body: data)
            throw NewsServiceError.server(status: http.statusCode)
        }

        do {
            let page = try decoder.decode(NewsPage.self, from: data)
            logSuccess(url: url, status: http.statusCode, body: data)
            return page
        } catch {
            logFailure("декодирование", url: url, detail: error.localizedDescription, body: data)
            throw NewsServiceError.decoding(error)
        }
    }

    nonisolated private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: Constants.Cache.memoryCapacity,
            diskCapacity: Constants.Cache.diskCapacity
        )
        return URLSession(configuration: configuration)
    }
}

#if DEBUG
private extension NewsService {
    /// Печатает успешный ответ в консоль - удобно сверять JSON с моделью.
    func logSuccess(url: URL, status: Int, body: Data) {
        print("[NewsService] ✅ \(status) \(url.absoluteString)\n\(body.prettyJSONString)")
    }

    /// Печатает причину ошибки и тело ответа, если есть - чтобы отлаживать сбои без прокси.
    func logFailure(_ reason: String, url: URL, detail: String? = nil, body: Data? = nil) {
        var lines = ["[NewsService] ❌ \(reason) \(url.absoluteString)"]
        if let detail, !detail.isEmpty {
            lines.append(detail)
        }
        if let body {
            lines.append(body.prettyJSONString)
        }
        print(lines.joined(separator: "\n"))
    }
}

private extension Data {
    /// Форматирует JSON для консоли; иначе отдаёт raw UTF-8 - чтобы лог читался и при битом теле.
    var prettyJSONString: String {
        guard
            let object = try? JSONSerialization.jsonObject(with: self),
            let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let string = String(data: pretty, encoding: .utf8)
        else {
            return String(data: self, encoding: .utf8) ?? "<binary \(count) bytes>"
        }
        return string
    }
}
#else
private extension NewsService {
    func logSuccess(url: URL, status: Int, body: Data) {}
    func logFailure(_ reason: String, url: URL, detail: String? = nil, body: Data? = nil) {}
}
#endif
