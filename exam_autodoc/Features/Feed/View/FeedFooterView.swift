//
//  FeedFooterView.swift
//  exam_autodoc
//
//  Футер секции: спиннер догрузки или кнопка повтора при ошибке пагинации.
//

import UIKit

final class FeedFooterView: UICollectionReusableView {

    private enum Constants {
        static let retryTitle = "Повторить"
    }

    /// Режим футера пагинации.
    enum Mode: Equatable {
        /// Догрузка не нужна или уже завершена - футер пустой.
        case idle
        /// Идёт запрос следующей страницы - спиннер.
        case loading
        /// Догрузка упала - кнопка «Повторить» для той же страницы.
        case retry
    }

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
    func apply(_ mode: Mode) {
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

    private func setup() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        var config = UIButton.Configuration.borderedProminent()
        config.title = Constants.retryTitle
        config.baseBackgroundColor = .adBrand
        config.baseForegroundColor = .white
        config.buttonSize = .small
        retryButton.configuration = config
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

    @objc private func retryTapped() {
        onRetry?()
    }
}
