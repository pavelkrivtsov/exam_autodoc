import UIKit

extension NewsFeedViewController {
    /// Запускает pull-to-refresh и завершает control с баннером при ошибке.
    @objc func handleRefresh() {
        Task {
            let failureMessage = await viewModel.refresh()
            refreshControl.finish(failureMessage: failureMessage)
        }
    }
}
