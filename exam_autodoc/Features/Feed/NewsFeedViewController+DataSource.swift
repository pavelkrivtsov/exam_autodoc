import UIKit

extension NewsFeedViewController {
    /// Регистрации ячеек и supplementary views — один раз при инициализации VC.
    func makeRegistrations() {
        cellRegistration = UICollectionView.CellRegistration<NewsCell, NewsItem> {
            [weak self] cell, _, item in
            guard let self else { return }
            cell.configure(with: item, imageTargetWidth: self.itemWidth())
        }

        footerRegistration = UICollectionView.SupplementaryRegistration<FeedFooterView>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] footer, _, _ in
            self?.footerView = footer
            footer.onRetry = { [weak self] in self?.viewModel.retry() }
            footer.apply(Self.footerMode(for: self?.viewModel.phase ?? .idle))
        }
    }

    /// Создаёт DiffableDataSource для ячеек и футера через CellRegistration.
    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, NewsItem> {
        let dataSource = UICollectionViewDiffableDataSource<Section, NewsItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: self.cellRegistration,
                for: indexPath,
                item: item
            )
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: self.footerRegistration,
                for: indexPath
            )
        }

        return dataSource
    }
}
