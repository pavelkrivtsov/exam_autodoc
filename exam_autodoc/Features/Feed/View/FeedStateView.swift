//
//  FeedStateView.swift
//  exam_autodoc
//
//  Центральный оверлей для состояний загрузки / пусто / ошибка.
//

import UIKit

private enum Constants {
    enum Text {
        static let empty = "Пока нет новостей"
        static let retry = "Повторить"
    }

    enum Icon {
        static let empty = "newspaper"
        static let error = "wifi.exclamationmark"
        static let pointSize: CGFloat = 48
    }

    enum Layout {
        static let stackSpacing: CGFloat = 12
    }
}

final class FeedStateView: UIView {
    /// Визуальное состояние заглушки поверх пустой ленты.
    enum State {
        /// Первичная загрузка - только спиннер.
        case loading
        /// API вернул пусто - иконка, текст и «Повторить».
        case empty
        /// Ошибка первой загрузки - иконка, текст ошибки и «Повторить».
        case error(String)
    }

    var onRetry: (() -> Void)?

    private let spinner = LoaderCircularView(size: .medium)
    private let imageView = UIImageView()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private lazy var stack = UIStackView(arrangedSubviews: [spinner, imageView, messageLabel, retryButton])

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ state: State) {
        isHidden = false
        switch state {
        case .loading:
            spinner.startAnimating()
            imageView.isHidden = true
            messageLabel.isHidden = true
            retryButton.isHidden = true

        case .empty:
            spinner.stopAnimating()
            imageView.isHidden = false
            imageView.image = UIImage(systemName: Constants.Icon.empty)
            messageLabel.isHidden = false
            messageLabel.text = Constants.Text.empty
            retryButton.isHidden = false

        case .error(let message):
            spinner.stopAnimating()
            imageView.isHidden = false
            imageView.image = UIImage(systemName: Constants.Icon.error)
            messageLabel.isHidden = false
            messageLabel.text = message
            retryButton.isHidden = false
        }
    }

    func hide() {
        isHidden = true
        spinner.stopAnimating()
    }

    private func setup() {
        backgroundColor = .adBackground

        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleToFill
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Constants.Icon.pointSize,
            weight: .regular
        )
        imageView.setContentHuggingPriority(.required, for: .vertical)

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .adSecondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var config = UIButton.Configuration.borderedProminent()
        config.title = Constants.Text.retry
        config.baseBackgroundColor = .adBrand
        config.baseForegroundColor = .white
        retryButton.configuration = config
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.axis = .vertical
        stack.spacing = Constants.Layout.stackSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
