//
//  FeedFooterView.swift
//  exam_autodoc
//
//  Футер секции: спиннер догрузки или кнопка повтора при ошибке пагинации.
//

import UIKit

/// Режим футера пагинации.
enum FeedFooterMode: Equatable {
    /// Догрузка не нужна или уже завершена - футер пустой.
    case idle
    /// Идёт запрос следующей страницы - спиннер.
    case loading
    /// Догрузка упала - кнопка «Повторить» для той же страницы.
    case retry
}

final class FeedFooterView: UICollectionReusableView {

    static let reuseID = "FeedFooterView"

    var onRetry: (() -> Void)?

    private let spinner = LoaderCircularView(size: .small)
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        apply(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Обновляет футер под фазу догрузки - спиннер, retry или пусто.
    func apply(_ mode: FeedFooterMode) {
        switch mode {
        case .idle:
            spinner.stopAnimating()
            retryButton.isHidden = true

        case .loading:
            retryButton.isHidden = true
            spinner.startAnimating()

        case .retry:
            spinner.stopAnimating()
            retryButton.isHidden = false
        }
    }
}

// MARK: - Настройка

private extension FeedFooterView {
    func setup() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        retryButton.configuration = .adBrandProminent(title: AppText.retry, size: .small)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        addSubview(retryButton)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc func retryTapped() {
        onRetry?()
    }
}
