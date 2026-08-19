//
//  RemoteImageView.swift
//  exam_autodoc
//
//  Переиспользуемый блок загрузки изображения: spinner, placeholder и fade-in.
//  Размер передаётся явно — без хаков в layoutSubviews ячейки.
//

import UIKit

@MainActor
final class RemoteImageView: UIView {

    enum LoadState {
        case loading
        case loaded
        case placeholder
    }

    nonisolated private enum Constants {
        static let minDimension: CGFloat = 1
        static let fadeDuration: TimeInterval = 0.2
        static let fallbackScreenScale: CGFloat = 2
    }

    private let imageView = UIImageView()
    private let spinner = LoaderCircularView(size: .small)

    private var loadTask: Task<Void, Never>?
    private var currentURL: URL?
    private var requestedKey: String?

    var onStateChange: ((LoadState) -> Void)?
    var imageContentView: UIView { imageView }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Запускает загрузку под переданный размер или показывает placeholder.
    func setImage(
        url: URL?,
        targetSize: CGSize,
        scale: CGFloat? = nil,
        placeholder: UIImage? = nil,
        fadeDuration: TimeInterval = Constants.fadeDuration
    ) {
        loadTask?.cancel()
        currentURL = url

        guard let url else {
            requestedKey = nil
            showPlaceholder(placeholder)
            return
        }

        guard targetSize.width > Constants.minDimension,
              targetSize.height > Constants.minDimension else {
            return
        }

        let effectiveScale = scale ?? adEffectiveScreenScale(fallback: Constants.fallbackScreenScale)
        let key = Self.cacheKey(url: url, targetSize: targetSize, scale: effectiveScale)
        guard key != requestedKey else { return }
        requestedKey = key

        showLoading()

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.image(
                    for: url,
                    targetSize: targetSize,
                    scale: effectiveScale
                )
                guard !Task.isCancelled, self.currentURL == url else { return }
                self.showLoaded(image, fadeDuration: fadeDuration)
            } catch {
                guard !Task.isCancelled, self.currentURL == url else { return }
                self.showPlaceholder(placeholder)
            }
        }
    }

    /// Сбрасывает состояние при переиспользовании ячейки.
    func prepareForReuse() {
        loadTask?.cancel()
        loadTask = nil
        currentURL = nil
        requestedKey = nil
        imageView.image = nil
        spinner.stopAnimating()
    }
}

// MARK: - Настройка

private extension RemoteImageView {
    func setup() {
        clipsToBounds = true
        backgroundColor = .adSurface

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        addSubview(imageView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func showLoading() {
        imageView.image = nil
        imageView.backgroundColor = .adSurface
        spinner.startAnimating()
        onStateChange?(.loading)
    }

    func showLoaded(_ image: UIImage, fadeDuration: TimeInterval) {
        spinner.stopAnimating()
        imageView.backgroundColor = .adSurface
        imageView.contentMode = .scaleToFill
        imageView.setImage(image, fadedWith: fadeDuration)
        onStateChange?(.loaded)
    }

    func showPlaceholder(_ placeholder: UIImage?) {
        spinner.stopAnimating()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .adPlaceholderBackground
        imageView.image = placeholder
        onStateChange?(.placeholder)
    }

    static func cacheKey(url: URL, targetSize: CGSize, scale: CGFloat) -> String {
        "\(url.absoluteString)|\(Int(max(targetSize.width, targetSize.height) * scale))"
    }
}
