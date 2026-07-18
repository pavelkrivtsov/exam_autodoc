//
//  FeedStateView.swift
//  exam_autodoc
//
//  Центральный оверлей для состояний загрузки / пусто / ошибка.
//

import UIKit

final class FeedStateView: UIView {
    enum State {
        case loading
        case empty
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
            imageView.image = UIImage(systemName: "newspaper")
            messageLabel.isHidden = false
            messageLabel.text = "Пока нет новостей"
            retryButton.isHidden = true

        case .error(let message):
            spinner.stopAnimating()
            imageView.isHidden = false
            imageView.image = UIImage(systemName: "wifi.exclamationmark")
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
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleToFill
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        imageView.setContentHuggingPriority(.required, for: .vertical)

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .adSecondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var config = UIButton.Configuration.borderedProminent()
        config.title = "Повторить"
        config.baseBackgroundColor = .adBrand
        config.baseForegroundColor = .white
        retryButton.configuration = config
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
