import UIKit

extension NewsFeedViewController {
    /// Создаёт DiffableDataSource для ячеек и футера.
    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, NewsItem> {
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

