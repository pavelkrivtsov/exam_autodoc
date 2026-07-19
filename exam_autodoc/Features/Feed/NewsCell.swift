//
//  NewsCell.swift
//  exam_autodoc
//
//  Ячейка ленты: изображение и заголовок (дата — внизу текстового блока).
//  Описание показывается только на экране деталей.
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

    // MARK: - Загрузка изображения

    private func resetImage() {
        imageView.image = nil
        imageView.backgroundColor = .adSurface
        if imageURL != nil {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            showPlaceholder()
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
                self.showPlaceholder()
            }
        }
    }

    /// Плейсхолдер для новостей без изображения (или при ошибке загрузки).
    private func showPlaceholder() {
        gradientLayer.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .adPlaceholderBackground
        imageView.image = UIImage(named: "logo")
    }

    private func apply(_ image: UIImage) {
        spinner.stopAnimating()
        gradientLayer.isHidden = false
        imageView.backgroundColor = .adSurface
        imageView.contentMode = .scaleToFill
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = image
        }
    }

    // MARK: - Настройка

    private func setup() {
        contentView.backgroundColor = .adSurface
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor
        ]
        gradientLayer.locations = [0.55, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        spinner.translatesAutoresizingMaskIntoConstraints = false

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        categoryLabel.textColor = .white
        categoryLabel.backgroundColor = UIColor.adBrand.withAlphaComponent(0.92)
        categoryLabel.layer.cornerRadius = 8
        categoryLabel.layer.cornerCurve = .continuous
        categoryLabel.clipsToBounds = true
        categoryLabel.textInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 3
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
        textStack.spacing = 16
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(spinner)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(textStack)

        let padding: CGFloat = 16
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

            textStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
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
