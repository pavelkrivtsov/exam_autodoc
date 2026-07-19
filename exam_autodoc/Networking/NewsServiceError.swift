//
//  NewsServiceError.swift
//  exam_autodoc
//
//  Ошибки сетевого слоя новостной ленты.
//

import Foundation

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
            return "Получен некорректный ответ сервера."

        case .server(let status):
            switch status {
            case 500...599:
                return "Сервер временно недоступен. Попробуйте позже."

            case 401, 403:
                return "Нет доступа к данным."

            case 404:
                return "Данные не найдены."

            default:
                return "Не удалось загрузить новости."
            }

        case .decoding:
            return "Не удалось обработать данные новостей."

        case .transport(let error):
            return Self.transportMessage(for: error)
        }
    }

    /// Понятный текст для сетевых сбоев вместо сырого URLError.
    private static func transportMessage(for error: any Error) -> String {
        guard let urlError = error as? URLError else {
            return "Проблема с сетью. Проверьте подключение."
        }
        switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed:
            return "Нет соединения с интернетом."

        case .timedOut:
            return "Превышено время ожидания."

        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "Не удалось связаться с сервером."

        case .networkConnectionLost:
            return "Соединение прервано."

        default:
            return "Проблема с сетью. Проверьте подключение."
        }
    }
}
