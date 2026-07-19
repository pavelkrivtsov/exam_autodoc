//
//  NewsFeedViewController.swift
//  exam_autodoc
//
//  Экран ленты. Compositional layout с адаптивным числом колонок (удобно для iPad)
//  и DiffableDataSource, управляемый ViewModel через Combine.
//

import UIKit
import Combine

private enum Constants {
    enum Text {
        static let title = "Новости"
    }

    enum Layout {
        static let spacing: CGFloat = 16
        static let columnWidth: CGFloat = 300
        static let estimatedItemHeight: CGFloat = 360
        static let footerHeight: CGFloat = 56
        static let stateHorizontalInset: CGFloat = 32
    }
}

final class NewsFeedViewController: UIViewController {

    /// Секции DiffableDataSource - только для этого экрана.
    nonisolated private enum Section: Hashable, Sendable {
        /// Единственная секция со всеми новостями - проще снапшоты и футер.
        case main
    }

    private let viewModel: NewsFeedViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var collectionView: UICollectionView = makeCollectionView()
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, NewsItem> = makeDataSource()
    private weak var footerView: FeedFooterView?

    private lazy var refreshControl = BrandRefreshControl()
    private let stateView = FeedStateView()

    /// Собирает экран с переданным или дефолтным ViewModel.
    init(viewModel: NewsFeedViewModel = NewsFeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    /// Собирает корень экрана без storyboard - сразу ставим collection и заглушку.
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .adBackground
        view = root

        configureCollectionView()
        configureStateView()
        _ = dataSource
    }

    /// Настраивает navigation и запускает первую загрузку - экран готов к данным.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.Text.title
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .adBrand
        bind()
        viewModel.onViewDidLoad()
    }

    /// Создаёт DiffableDataSource для ячеек и футера - в классе из‑за приватного `Section` в сигнатуре.
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, NewsItem> {
        let dataSource = UICollectionViewDiffableDataSource<Section, NewsItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewsCell.reuseID,
                for: indexPath
            ) as? NewsCell else {
                assertionFailure("Ожидалась NewsCell для \(NewsCell.reuseID)")
                return UICollectionViewCell()
            }
            cell.configure(with: item)
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FeedFooterView.reuseID,
                for: indexPath
            ) as? FeedFooterView else {
                assertionFailure("Ожидался FeedFooterView для \(FeedFooterView.reuseID)")
                return nil
            }
            self?.footerView = footer
            footer.onRetry = { [weak self] in self?.viewModel.retry() }
            footer.apply(Self.footerMode(for: self?.viewModel.phase ?? .idle))
            return footer
        }

        return dataSource
    }
}

// MARK: - Настройка

private extension NewsFeedViewController {
    /// Собирает collection view с layout и регистрацией ячеек - единая фабрика UI ленты.
    func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.register(NewsCell.self, forCellWithReuseIdentifier: NewsCell.reuseID)
        collectionView.register(
            FeedFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: FeedFooterView.reuseID
        )
        return collectionView
    }

    /// Встраивает collection на весь экран и подключает refresh - лента занимает root view.
    func configureCollectionView() {
        view.addSubview(collectionView)

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Compositional layout с адаптивным числом колонок - удобно на iPhone и iPad.
    func makeLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = Constants.Layout.spacing

        return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns = max(1, Int(width / Constants.Layout.columnWidth))
            let spacing = Constants.Layout.spacing

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(Constants.Layout.estimatedItemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(Constants.Layout.estimatedItemHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: spacing, leading: spacing, bottom: spacing, trailing: spacing
            )

            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(Constants.Layout.footerHeight)
            )
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            section.boundarySupplementaryItems = [footer]
            return section
        }, configuration: configuration)
    }

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
                constant: Constants.Layout.stateHorizontalInset
            ),
            stateView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.Layout.stateHorizontalInset
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

// MARK: - UICollectionViewDelegate

extension NewsFeedViewController: UICollectionViewDelegate {
    /// При показе ячейки просит ViewModel догрузить страницу - пагинация без отдельного скролл-хендлера.
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.item)
    }

    /// Открывает экран детали выбранной новости.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = NewsDetailViewController(item: item)
        navigationController?.pushViewController(detail, animated: true)
    }
}
