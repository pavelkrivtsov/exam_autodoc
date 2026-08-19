import SafariServices

extension NewsDetailViewController: SFSafariViewControllerDelegate {
    /// Если начальная загрузка страницы упала - закрываем Safari и сообщаем на деталях.
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {
        guard !didLoadSuccessfully else { return }
        controller.dismiss(animated: true) { [weak self] in
            self?.showBrokenLinkToast()
        }
    }
}

