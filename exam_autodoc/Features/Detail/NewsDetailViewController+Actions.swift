import UIKit
import SafariServices

private enum NewsDetailActionsConstants {
    enum Text {
        static let brokenLink = "Не удалось открыть ссылку"
    }
}

extension NewsDetailViewController {
    /// Открывает fullURL во встроенном Safari - битую ссылку ловим до краша и через delegate.
    @objc func openFullArticle() {
        guard let url = item.fullURL, url.isSafariCompatible else {
            showBrokenLinkToast()
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        present(safari, animated: true)
    }

    /// Баннер под safe area - мягкий фидбек без модалки.
    func showBrokenLinkToast() {
        toast.show(
            NewsDetailActionsConstants.Text.brokenLink,
            in: view,
            below: view.safeAreaLayoutGuide.topAnchor
        )
    }
}

