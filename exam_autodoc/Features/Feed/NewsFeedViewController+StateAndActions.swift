import UIKit
import Combine

extension NewsFeedViewController {
    /// Кладёт оверлей заглушки поверх ленты - loading/empty/error без ломки large title.
    func configureStateView() {
        stateView.translatesAutoresizingMaskIntoConstraints = false
        stateView.isHidden = true
        stateView.onRetry = { [weak self] in self?.viewModel.retry() }
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stateView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: NewsFeedConstants.Layout.stateHorizontalInset
            ),
            stateView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -NewsFeedConstants.Layout.stateHorizontalInset
            )
        ])
    }

    // MARK: - Привязка

    /// Подписывается на items и phase ViewModel - UI обновляется декларативно.
    func bind() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.apply(items)
            }
            .store(in: &cancellables)

        viewModel.$phase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                self?.render(phase)
            }
            .store(in: &cancellables)
    }

    /// Применяет снапшот DiffableDataSource - список на экране совпадает с ViewModel.
    func apply(_ items: [NewsItem], animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    /// Переводит фазу ViewModel в stub или ленту - единая точка UI-состояний.
    func render(_ phase: NewsFeedPhase) {
        footerView?.apply(Self.footerMode(for: phase))

        let stubState: FeedState?
        switch phase {
        case .loadingFirst where viewModel.items.isEmpty:
            stubState = .loading

        case .error(let message) where viewModel.items.isEmpty:
            stubState = .error(message)

        case .empty:
            stubState = .empty

        default:
            stubState = nil
        }

        if let stubState {
            // Оверлей поверх ленты: large title не трогаем - иначе UIKit не вернёт его после .never.
            showStub(stubState)
        } else {
            showFeed()
        }
    }

    /// Заглушка поверх пустой ленты: без скролла и refresh, large title остаётся.
    func showStub(_ state: FeedState) {
        collectionView.isHidden = false
        collectionView.isScrollEnabled = false
        collectionView.refreshControl = nil
        stateView.show(state)
    }

    /// Обычная лента со скроллом и pull-to-refresh.
    func showFeed() {
        stateView.hide()
        collectionView.isHidden = false
        collectionView.isScrollEnabled = true
        collectionView.refreshControl = refreshControl
    }

    /// Режим футера по фазе ViewModel - спиннер, retry или пусто.
    static func footerMode(for phase: NewsFeedPhase) -> FeedFooterMode {
        switch phase {
        case .loadingNext:
            return .loading

        case .pagingError:
            return .retry

        default:
            return .idle
        }
    }

    // MARK: - Действия

    /// Запускает pull-to-refresh и завершает control с баннером при ошибке.
    @objc func handleRefresh() {
        Task {
            let failureMessage = await viewModel.refresh()
            refreshControl.finish(failureMessage: failureMessage)
        }
    }
}

