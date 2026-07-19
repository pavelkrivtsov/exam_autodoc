//
//  NewsEndpoint.swift
//  exam_autodoc
//
//  Формирует URL страниц. Нумерация страниц с 1, как в API.
//

import Foundation

enum NewsEndpoint {
    static let baseURL: URL = {
        guard let url = URL(string: "https://webapi.autodoc.ru/api/news") else {
            preconditionFailure("Некорректный NewsEndpoint.baseURL")
        }
        return url
    }()

    static func page(_ page: Int, pageSize: Int) -> URL {
        baseURL.appending(path: "\(page)/\(pageSize)")
    }
}
