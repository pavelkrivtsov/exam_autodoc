//
//  NewsServiceError.swift
//  exam_autodoc
//
//  Ошибки сетевого слоя новостной ленты.
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
