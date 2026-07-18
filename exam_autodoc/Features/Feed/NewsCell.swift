//
//  NewsCell.swift
//  exam_autodoc
//
//  Ячейка ленты: изображение + заголовок, чип категории и дата публикации.
//  Картинки грузятся лениво и отменяются при reuse — для плавного скролла.
//

import UIKit

final class NewsCell: UICollectionViewCell {
    static let reuseID = "NewsCell"
    static let imageAspectRatio: CGFloat = 0.62

    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let categoryLabel = PaddingLabel()
    private let dateLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var imageURL: URL?
    private var requestedKey: String?
    private var imageTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Конфигурация

    func configure(with item: NewsItem) {
        titleLabel.text = item.title
        categoryLabel.text = item.categoryType
        categoryLabel.isHidden = item.categoryType.isEmpty
        dateLabel.text = item.publishedDate.map(DateDisplay.string(from:))
        dateLabel.isHidden = item.publishedDate == nil

        imageURL = item.imageURL
        resetImage()
        // На переиспользовании размеры ячейки уже валидны, а layoutSubviews может
        // не вызваться (bounds не меняются) — поэтому запускаем загрузку здесь,
        // чтобы сразу подхватить закэшированное изображение.
        loadImageIfNeeded()
    }

    // MARK: - Вёрстка

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
        loadImageIfNeeded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageURL = nil
        requestedKey = nil
        resetImage()
    }

    // MARK: - Загрузка изображения

    private func resetImage() {
        imageView.image = nil
        imageView.backgroundColor = .secondarySystemBackground
        if imageURL != nil {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            showPlaceholderGlyph()
        }
    }

    private func loadImageIfNeeded() {
        guard let url = imageURL else { return }
        // Фрейм imageView устанавливается поздно в self-sizing проходе,
        // поэтому берём размер от ширины contentView — она надёжна.
        let width = contentView.bounds.width
        guard width > 1 else { return }
        let size = CGSize(width: width, height: width * Self.imageAspectRatio)

        let scale = window?.screen.scale ?? traitCollection.displayScale
        let effectiveScale = scale > 0 ? scale : 2
        let key = "\(url.absoluteString)|\(Int(size.width * effectiveScale))"
        guard key != requestedKey else { return }
        requestedKey = key

        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.image(for: url, targetSize: size, scale: effectiveScale)
                if Task.isCancelled || self.imageURL != url { return }
                self.apply(image)
            } catch {
                if Task.isCancelled || self.imageURL != url { return }
                self.spinner.stopAnimating()
                self.showPlaceholderGlyph()
            }
        }
    }

    private func apply(_ image: UIImage) {
        spinner.stopAnimating()
        imageView.contentMode = .scaleAspectFill
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = image
        }
    }

    private func showPlaceholderGlyph() {
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "photo", withConfiguration: config)?
            .withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
    }

    // MARK: - Настройка

    private func setup() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor
        ]
        gradientLayer.locations = [0.55, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        categoryLabel.textColor = .white
        categoryLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        categoryLabel.layer.cornerRadius = 8
        categoryLabel.layer.cornerCurve = .continuous
        categoryLabel.clipsToBounds = true
        categoryLabel.textInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 3
        titleLabel.textColor = .label

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(spinner)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: Self.imageAspectRatio),

            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            categoryLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 10),
            categoryLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -10),

            textStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

/// `UILabel` с настраиваемыми отступами — для чипа категории.
final class PaddingLabel: UILabel {
    var textInsets: UIEdgeInsets = .zero { didSet { invalidateIntrinsicContentSize() } }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
