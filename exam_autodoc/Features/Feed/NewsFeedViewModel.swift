//
//  NewsFeedViewModel.swift
//  exam_autodoc
//
//  ViewModel ленты новостей (MVVM). Состояние публикуется через Combine,
//  чтобы контроллер реагировал декларативно. Весь I/O — async/await.
//

import Foundation
import Combine

@MainActor
final class NewsFeedViewModel {

    /// Высокоуровневая фаза UI, отдельно от `items`, чтобы показывать
    /// спиннеры/ошибки без изменения набора данных.
    enum Phase: Equatable {
        case idle
        case loadingFirst
        case loadingNext
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var items: [NewsItem] = []
    @Published private(set) var phase: Phase = .idle

    private let service: any NewsServing
    private let pageSize: Int

    private var nextPage = 1
    private var totalCount = 0
    private var seenIDs = Set<Int>()
    private var loadTask: Task<Void, Never>?

    nonisolated init(service: any NewsServing = NewsService(), pageSize: Int = 9) {
        self.service = service
        self.pageSize = pageSize
    }

    var hasMorePages: Bool {
        totalCount == 0 || items.count < totalCount
    }

    private var isLoading: Bool {
        phase == .loadingFirst || phase == .loadingNext
    }

    // MARK: - Действия

    func onViewDidLoad() {
        guard items.isEmpty else { return }
        loadFirstPage()
    }

    func loadFirstPage() {
        guard !isLoading else { return }
        resetPagination()
        phase = .loadingFirst
        startLoad(page: nextPage, replacingContents: true)
    }

    func refresh() async {
        loadTask?.cancel()
        resetPagination()
        phase = .loadingFirst
        await load(page: nextPage, replacingContents: true)
    }

    /// Вызывается при показе ячеек; запускает следующую страницу,
    /// пока пользователь ещё не дошёл до конца списка.
    func loadNextPageIfNeeded(currentIndex: Int) {
        guard !isLoading, hasMorePages, !items.isEmpty else { return }
        let threshold = items.count - max(pageSize / 3, 3)
        guard currentIndex >= threshold else { return }
        phase = .loadingNext
        startLoad(page: nextPage, replacingContents: false)
    }

    func retry() {
        if items.isEmpty {
            loadFirstPage()
        } else {
            phase = .loadingNext
            startLoad(page: nextPage, replacingContents: false)
        }
    }

    // MARK: - Загрузка

    private func startLoad(page: Int, replacingContents: Bool) {
        loadTask = Task { [weak self] in
            await self?.load(page: page, replacingContents: replacingContents)
        }
    }

    private func load(page: Int, replacingContents: Bool) async {
        do {
            let result = try await service.fetchNews(page: page, pageSize: pageSize)
            if Task.isCancelled { return }

            totalCount = result.totalCount
            if replacingContents {
                seenIDs.removeAll(keepingCapacity: true)
                items.removeAll(keepingCapacity: true)
            }

            let fresh = result.news.filter { seenIDs.insert($0.id).inserted }
            items.append(contentsOf: fresh)
            nextPage = page + 1

            phase = items.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            if Task.isCancelled { return }
            if items.isEmpty {
                phase = .error(Self.message(for: error))
            } else {
                // Оставляем уже загруженный контент; ошибку догрузки
                // не показываем поверх списка — пользователь может повторить.
                phase = .loaded
            }
        }
    }

    private func resetPagination() {
        loadTask?.cancel()
        nextPage = 1
        totalCount = 0
    }

    private static func message(for error: any Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
