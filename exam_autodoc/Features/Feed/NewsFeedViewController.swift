//
//  NewsFeedViewController.swift
//  exam_autodoc
//
//  Экран ленты. Compositional layout с адаптивным числом колонок (удобно для iPad)
//  и DiffableDataSource, управляемый ViewModel через Combine.
//

import UIKit
import Combine

private nonisolated enum FeedSection: Hashable, Sendable {
    case main
}

final class NewsFeedViewController: UIViewController {

    private typealias Section = FeedSection

    private let viewModel: NewsFeedViewModel
    private var cancellables = Set<AnyCancellable>()

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, NewsItem>!
    private weak var footerView: FeedFooterView?

    private lazy var refreshControl = BrandRefreshControl()
    private let stateView = FeedStateView()

    init(viewModel: NewsFeedViewModel = NewsFeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл

    /// Создаём иерархию программно — без storyboard/xib.
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .adBackground
        view = root

        configureCollectionView()
        configureStateView()
        configureDataSource()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новости"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .adBrand
        bind()
        viewModel.onViewDidLoad()
    }

    // MARK: - Настройка

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
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

    private func makeLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16

        return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns = max(1, Int(width / 300))
            let spacing: CGFloat = 16

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(360)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(360)
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
                heightDimension: .absolute(44)
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

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, NewsItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewsCell.reuseID, for: indexPath
            ) as! NewsCell
            cell.configure(with: item)
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FeedFooterView.reuseID,
                for: indexPath
            ) as! FeedFooterView
            self?.footerView = footer
            footer.setLoading(self?.viewModel.phase == .loadingNext)
            return footer
        }
    }

    private func configureStateView() {
        stateView.translatesAutoresizingMaskIntoConstraints = false
        stateView.isHidden = true
        stateView.onRetry = { [weak self] in self?.viewModel.retry() }
        view.addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Привязка

    private func bind() {
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

    private func apply(_ items: [NewsItem], animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func render(_ phase: NewsFeedViewModel.Phase) {
        footerView?.setLoading(phase == .loadingNext)

        switch phase {
        case .loadingFirst where viewModel.items.isEmpty:
            stateView.show(.loading)
        case .error(let message) where viewModel.items.isEmpty:
            stateView.show(.error(message))
        case .empty:
            stateView.show(.empty)
        default:
            stateView.hide()
        }

        if phase != .loadingFirst, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    // MARK: - Действия

    @objc private func handleRefresh() {
        Task { await viewModel.refresh() }
    }
}

// MARK: - UICollectionViewDelegate

extension NewsFeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = NewsDetailViewController(item: item)
        navigationController?.pushViewController(detail, animated: true)
    }
}
