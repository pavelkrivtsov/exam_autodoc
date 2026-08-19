import UIKit
import SafariServices

private enum NewsDetailActionsConstants {
    enum Text {
        static let brokenLink = "Не удалось открыть ссылку"
    }
}

extension NewsDetailViewController {
    @objc func openFullArticle() {
        guard let url = viewModel.articleURL else {
            showBrokenLinkToast()
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        present(safari, animated: true)
    }

    func showBrokenLinkToast() {
        toast.show(
            NewsDetailActionsConstants.Text.brokenLink,
            in: view,
            below: view.safeAreaLayoutGuide.topAnchor
        )
    }
}
