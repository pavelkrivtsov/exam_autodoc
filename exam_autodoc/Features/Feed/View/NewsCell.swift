//
//  NewsCell.swift
//  exam_autodoc
//
//  Ячейка ленты: изображение и заголовок (дата — внизу текстового блока).
//  Описание показывается только на экране деталей.
//

import UIKit

private enum Constants {
    enum Image {
        static let placeholder = "placeholder"
        static let aspectRatio: CGFloat = 0.62
        static let minWidth: CGFloat = 1
        static let fallbackScreenScale: CGFloat = 2
        static let fadeDuration: TimeInterval = 0.2
    }

    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let categoryCornerRadius: CGFloat = 8
        static let categoryFontSize: CGFloat = 11
        static let categoryAlpha: CGFloat = 0.92
        static let categoryInset = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        static let categoryEdge: CGFloat = 10
        static let textStackSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let textTopSpacing: CGFloat = 14
        static let titleMaxLines = 3
        static let gradientStartLocation: NSNumber = 0.55
        static let gradientEndLocation: NSNumber = 1.0
        static let gradientEndAlpha: CGFloat = 0.35
    }
}

final class NewsCell: UICollectionViewCell {
    static let reuseID = "NewsCell"

    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let categoryLabel = PaddingLabel()
    private let dateLabel = UILabel()
    private let spinner = LoaderCircularView(size: .small)

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
}

// MARK: - Загрузка изображения

private extension NewsCell {
    func resetImage() {
        imageView.image = nil
        imageView.backgroundColor = .adSurface
        if imageURL != nil {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            showPlaceholder()
        }
    }

    func loadImageIfNeeded() {
        guard let url = imageURL else { return }
        // Фрейм imageView устанавливается поздно в self-sizing проходе,
        // поэтому берём размер от ширины contentView — она надёжна.
        let width = contentView.bounds.width
        guard width > Constants.Image.minWidth else { return }
        let size = CGSize(width: width, height: width * Constants.Image.aspectRatio)

        let effectiveScale = adEffectiveScreenScale(fallback: Constants.Image.fallbackScreenScale)
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
                self.showPlaceholder()
            }
        }
    }

    /// Плейсхолдер для новостей без изображения (или при ошибке загрузки).
    func showPlaceholder() {
        gradientLayer.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .adPlaceholderBackground
        imageView.image = UIImage(named: Constants.Image.placeholder)
    }

    func apply(_ image: UIImage) {
        spinner.stopAnimating()
        gradientLayer.isHidden = false
        imageView.backgroundColor = .adSurface
        imageView.contentMode = .scaleToFill
        imageView.setImage(image, fadedWith: Constants.Image.fadeDuration)
    }
}

// MARK: - Настройка

private extension NewsCell {
    func setup() {
        contentView.backgroundColor = .adSurface
        contentView.layer.cornerRadius = Constants.Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(Constants.Layout.gradientEndAlpha).cgColor
        ]
        gradientLayer.locations = [
            Constants.Layout.gradientStartLocation,
            Constants.Layout.gradientEndLocation
        ]
        imageView.layer.addSublayer(gradientLayer)

        spinner.translatesAutoresizingMaskIntoConstraints = false

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = .systemFont(ofSize: Constants.Layout.categoryFontSize, weight: .semibold)
        categoryLabel.textColor = .white
        categoryLabel.backgroundColor = UIColor.adBrand.withAlphaComponent(Constants.Layout.categoryAlpha)
        categoryLabel.layer.cornerRadius = Constants.Layout.categoryCornerRadius
        categoryLabel.layer.cornerCurve = .continuous
        categoryLabel.clipsToBounds = true
        categoryLabel.textInsets = Constants.Layout.categoryInset

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = Constants.Layout.titleMaxLines
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textColor = .adPrimaryText
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = .adTertiaryText
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // Нижний блок: заголовок + дата. Описание — только на экране деталей.
        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = Constants.Layout.textStackSpacing
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(spinner)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(textStack)

        let padding = Constants.Layout.contentPadding
        let categoryEdge = Constants.Layout.categoryEdge
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor,
                multiplier: Constants.Image.aspectRatio
            ),

            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            categoryLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: categoryEdge),
            categoryLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -categoryEdge),
            categoryLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: imageView.trailingAnchor,
                constant: -categoryEdge
            ),

            textStack.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: Constants.Layout.textTopSpacing
            ),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
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
