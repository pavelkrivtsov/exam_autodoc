//
//  NewsFeedViewModel.swift
//  exam_autodoc
//
//  ViewModel ленты новостей (MVVM). Состояние публикуется через Combine,
//  чтобы контроллер реагировал декларативно. Весь I/O — async/await.
//

import Foundation
import Combine

nonisolated private enum Constants {
    static let defaultPageSize = 15
    /// Догрузка, когда до конца осталось около 1/3 страницы (минимум 3 ячейки).
    static let preloadPageFraction = 3
    static let preloadMinRemaining = 3
    static let firstPage = 1
}

@MainActor
final class NewsFeedViewModel {

    /// Высокоуровневая фаза UI, отдельно от `items`, чтобы показывать
    /// спиннеры/ошибки без изменения набора данных.
    enum Phase: Equatable {
        /// Стартовое состояние до первого запроса - лента ещё не трогалась.
        case idle
        /// Идёт загрузка первой страницы (или pull-to-refresh) - нужен полноэкранный/оверлейный индикатор.
        case loadingFirst
        /// Идёт догрузка следующей страницы - в футере спиннер.
        case loadingNext
        /// Данные успешно на экране - обычный режим ленты.
        case loaded
        /// Сервер вернул пустой список - заглушка «нет новостей».
        case empty
        /// Первая загрузка упала при пустой ленте - заглушка с текстом и «Повторить».
        case error(String)
        /// Догрузка страницы не удалась - в футере кнопка повтора той же nextPage.
        case pagingError
    }

    @Published private(set) var items: [NewsItem] = []
    @Published private(set) var phase: Phase = .idle

    private let service: any NewsServing
    private let pageSize: Int

    private var nextPage = Constants.firstPage
    private var totalCount = 0
    private var seenIDs = Set<Int>()
    private var loadTask: Task<Void, Never>?

    nonisolated init(
        service: any NewsServing = NewsService(),
        pageSize: Int = Constants.defaultPageSize
    ) {
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

    /// Pull-to-refresh. Возвращает текст ошибки для баннера или `nil` при успехе.
    @discardableResult
    func refresh() async -> String? {
        loadTask?.cancel()
        // Пагинацию не сбрасываем заранее - при ошибке остаются прежние nextPage/totalCount.
        phase = .loadingFirst
        return await load(page: Constants.firstPage, replacingContents: true)
    }

    /// Вызывается при показе ячеек; запускает следующую страницу,
    /// пока пользователь ещё не дошёл до конца списка.
    func loadNextPageIfNeeded(currentIndex: Int) {
        // После ошибки пагинации ждём явный retry в футере - без автоповторов при скролле.
        guard phase != .pagingError else { return }
        guard !isLoading, hasMorePages, !items.isEmpty else { return }
        let threshold = items.count - max(
            pageSize / Constants.preloadPageFraction,
            Constants.preloadMinRemaining
        )
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

    @discardableResult
    private func load(page: Int, replacingContents: Bool) async -> String? {
        do {
            let result = try await service.fetchNews(page: page, pageSize: pageSize)
            if Task.isCancelled { return nil }

            totalCount = result.totalCount
            if replacingContents {
                seenIDs.removeAll(keepingCapacity: true)
                items.removeAll(keepingCapacity: true)
            }

            let fresh = result.news.filter { seenIDs.insert($0.id).inserted }
            items.append(contentsOf: fresh)
            nextPage = page + 1

            phase = items.isEmpty ? .empty : .loaded
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            if Task.isCancelled { return nil }
            if items.isEmpty {
                phase = .error(Self.message(for: error))
                return nil
            } else if replacingContents {
                // Неудачный refresh: ленту оставляем, баннер покажет BrandRefreshControl.
                phase = .loaded
                return "Не удалось обновить"
            } else {
                // Ошибка догрузки - retry в футере на ту же nextPage.
                phase = .pagingError
                return nil
            }
        }
    }

    private func resetPagination() {
        loadTask?.cancel()
        nextPage = Constants.firstPage
        totalCount = 0
    }

    private static func message(for error: any Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
