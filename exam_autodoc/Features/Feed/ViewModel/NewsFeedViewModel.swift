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
    /// Размер страницы по умолчанию - баланс между числом запросов и объёмом данных.
    static let defaultPageSize = 15
    /// Делитель pageSize для порога догрузки - около 1/3 страницы до конца.
    static let preloadPageFraction = 3
    /// Нижняя граница «осталось ячеек» для preload - не дёргать API слишком рано на коротких страницах.
    static let preloadMinRemaining = 3
    /// Номер первой страницы API - сброс и старт пагинации с начала.
    static let firstPage = 1

    enum Text {
        /// Текст баннера при неудачном pull-to-refresh - лента уже на экране, полный stub не нужен.
        static let refreshFailed = "Не удалось обновить"
    }
}

/// Высокоуровневая фаза UI ленты, отдельно от `items`.
enum NewsFeedPhase: Equatable {
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

@MainActor
final class NewsFeedViewModel {

    @Published private(set) var items: [NewsItem] = []
    @Published private(set) var phase: NewsFeedPhase = .idle

    private let service: any NewsServing
    private let pageSize: Int

    private var nextPage = Constants.firstPage
    private var totalCount = 0
    private var seenIDs = Set<Int>()
    private var loadTask: Task<Void, Never>?

    /// DI для сервиса и размера страницы - nonisolated из‑за default MainActor isolation.
    nonisolated init(
        service: any NewsServing = NewsService(),
        pageSize: Int = Constants.defaultPageSize
    ) {
        self.service = service
        self.pageSize = pageSize
    }

    /// Есть ли ещё страницы по totalCount - порог для пагинации.
    var hasMorePages: Bool {
        totalCount == 0 || items.count < totalCount
    }

    /// Идёт ли сейчас первая загрузка или догрузка - чтобы не запускать параллельные запросы.
    private var isLoading: Bool {
        phase == .loadingFirst || phase == .loadingNext
    }

    // MARK: - Действия

    /// Стартует первую загрузку при пустой ленте - entry point из viewDidLoad.
    func onViewDidLoad() {
        guard items.isEmpty else { return }
        loadFirstPage()
    }

    /// Сбрасывает пагинацию и грузит первую страницу - stub loading / retry с пустого экрана.
    func loadFirstPage() {
        guard !isLoading else { return }
        resetPagination()
        phase = .loadingFirst
        startLoad(page: nextPage, replacingContents: true)
    }

    /// Pull-to-refresh: возвращает текст ошибки для баннера или `nil` при успехе.
    @discardableResult
    func refresh() async -> String? {
        loadTask?.cancel()
        // Пагинацию не сбрасываем заранее - при ошибке остаются прежние nextPage/totalCount.
        phase = .loadingFirst
        return await load(page: Constants.firstPage, replacingContents: true)
    }

    /// При показе ячеек запускает следующую страницу заранее - пользователь не упирается в конец списка.
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

    /// Повтор после ошибки: пустая лента → первая страница, иначе та же nextPage в футере.
    func retry() {
        if items.isEmpty {
            loadFirstPage()
        } else {
            phase = .loadingNext
            startLoad(page: nextPage, replacingContents: false)
        }
    }
}

// MARK: - Загрузка

private extension NewsFeedViewModel {
    /// Оборачивает async-загрузку в Task - можно отменить при новом запросе.
    func startLoad(page: Int, replacingContents: Bool) {
        loadTask = Task { [weak self] in
            await self?.load(page: page, replacingContents: replacingContents)
        }
    }

    /// Тянет страницу у сервиса и обновляет items/phase - единая точка успеха и ошибок.
    @discardableResult
    func load(page: Int, replacingContents: Bool) async -> String? {
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
                return Constants.Text.refreshFailed
            } else {
                // Ошибка догрузки - retry в футере на ту же nextPage.
                phase = .pagingError
                return nil
            }
        }
    }

    /// Обнуляет nextPage/totalCount и отменяет текущий Task - чистый старт первой страницы.
    func resetPagination() {
        loadTask?.cancel()
        nextPage = Constants.firstPage
        totalCount = 0
    }

    /// Текст для stub из LocalizedError или fallback localizedDescription.
    static func message(for error: any Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
