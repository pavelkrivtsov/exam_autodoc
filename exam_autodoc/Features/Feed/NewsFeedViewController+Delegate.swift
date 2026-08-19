import UIKit

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
        let detail = NewsDetailViewController(viewModel: NewsDetailViewModel(item: item))
        navigationController?.pushViewController(detail, animated: true)
    }
}
