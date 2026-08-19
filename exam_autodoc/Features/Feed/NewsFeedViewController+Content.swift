import UIKit

extension NewsFeedViewController {
    /// Собирает collection view с layout - единая фабрика UI ленты.
    func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        return collectionView
    }

    /// Ширина одной ячейки по тем же правилам, что и compositional layout.
    func itemWidth() -> CGFloat {
        let spacing = NewsFeedConstants.Layout.spacing
        let width = collectionView.bounds.width
        let columns = max(1, Int(width / NewsFeedConstants.Layout.columnWidth))
        let contentWidth = width - spacing * 2
        let interItemSpacing = spacing * CGFloat(columns - 1)
        return (contentWidth - interItemSpacing) / CGFloat(columns)
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

    /// Compositional layout с адаптивным числом колонок - удобно на iPhone и iPad.
    func makeLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = NewsFeedConstants.Layout.spacing

        return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns = max(1, Int(width / NewsFeedConstants.Layout.columnWidth))
            let spacing = NewsFeedConstants.Layout.spacing

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(NewsFeedConstants.Layout.estimatedItemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(NewsFeedConstants.Layout.estimatedItemHeight)
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
                heightDimension: .absolute(NewsFeedConstants.Layout.footerHeight)
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
}
