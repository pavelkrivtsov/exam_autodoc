//
//  NewsServiceError.swift
//  exam_autodoc
//
//  Ошибки сетевого слоя новостной ленты.
//

import Foundation

private enum Constants {
    enum Text {
        static let invalidResponse = "Получен некорректный ответ сервера."
        static let serverUnavailable = "Сервер временно недоступен. Попробуйте позже."
        static let accessDenied = "Нет доступа к данным."
        static let notFound = "Данные не найдены."
        static let loadFailed = "Не удалось загрузить новости."
        static let decodingFailed = "Не удалось обработать данные новостей."
        static let networkGeneric = "Проблема с сетью. Проверьте подключение."
        static let noInternet = "Нет соединения с интернетом."
        static let timedOut = "Превышено время ожидания."
        static let hostUnreachable = "Не удалось связаться с сервером."
        static let connectionLost = "Соединение прервано."
    }
}

enum NewsServiceError: LocalizedError {
    /// Ответ не HTTPURLResponse - дальше разбирать нечего.
    case invalidResponse
    /// Сервер вернул неуспешный статус - показываем понятный текст по коду.
    case server(status: Int)
    /// JSON не совпал с моделью - данные с сервера битые или контракт изменился.
    case decoding(any Error)
    /// Сбой на уровне сети/URLSession - нет связи, таймаут и т.п.
    case transport(any Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return Constants.Text.invalidResponse

        case .server(let status):
            switch status {
            case 500...599:
                return Constants.Text.serverUnavailable

            case 401, 403:
                return Constants.Text.accessDenied

            case 404:
                return Constants.Text.notFound

            default:
                return Constants.Text.loadFailed
            }

        case .decoding:
            return Constants.Text.decodingFailed

        case .transport(let error):
            return Self.transportMessage(for: error)
        }
    }

    /// Понятный текст для сетевых сбоев вместо сырого URLError.
    private static func transportMessage(for error: any Error) -> String {
        guard let urlError = error as? URLError else {
            return Constants.Text.networkGeneric
        }
        switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed:
            return Constants.Text.noInternet

        case .timedOut:
            return Constants.Text.timedOut

        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return Constants.Text.hostUnreachable

        case .networkConnectionLost:
            return Constants.Text.connectionLost

        default:
            return Constants.Text.networkGeneric
        }
    }
}
