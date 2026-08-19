//
//  NewsFeedViewController.swift
//  exam_autodoc
//
//  Экран ленты. Compositional layout с адаптивным числом колонок (удобно для iPad)
//  и DiffableDataSource, управляемый ViewModel через Combine.
//

import UIKit
import Combine

enum NewsFeedConstants {
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
    nonisolated enum Section: Hashable, Sendable {
        /// Единственная секция со всеми новостями - проще снапшоты и футер.
        case main
    }

    let viewModel: NewsFeedViewModel
    var cancellables = Set<AnyCancellable>()

    lazy var collectionView: UICollectionView = makeCollectionView()
    lazy var dataSource: UICollectionViewDiffableDataSource<Section, NewsItem> = makeDataSource()
    weak var footerView: FeedFooterView?

    lazy var refreshControl = BrandRefreshControl()
    let stateView = FeedStateView()

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
        title = NewsFeedConstants.Text.title
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .adBrand
        bind()
        viewModel.onViewDidLoad()
    }
}
