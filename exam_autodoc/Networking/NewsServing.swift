//
//  NewsServing.swift
//  exam_autodoc
//
//  Абстракция сервиса новостей: ViewModel можно тестировать со стабом.
//

import Foundation

protocol NewsServing: Sendable {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage
}
