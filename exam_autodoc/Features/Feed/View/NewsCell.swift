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

    private let remoteImageView = RemoteImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let categoryLabel = PaddingLabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Конфигурация

    /// `imageTargetWidth` — ширина ячейки из layout, чтобы загрузчик знал размер без layoutSubviews.
    func configure(with item: NewsItem, imageTargetWidth: CGFloat) {
        titleLabel.text = item.title
        categoryLabel.text = item.categoryType
        categoryLabel.isHidden = item.categoryType.isEmpty
        dateLabel.text = item.publishedDate.map(DateDisplay.string(from:))
        dateLabel.isHidden = item.publishedDate == nil

        let imageHeight = imageTargetWidth * Constants.Image.aspectRatio
        let targetSize = CGSize(width: imageTargetWidth, height: imageHeight)
        remoteImageView.onStateChange = { [weak self] state in
            self?.gradientLayer.isHidden = state != .loaded
        }
        remoteImageView.setImage(
            url: item.imageURL,
            targetSize: targetSize,
            placeholder: UIImage(named: Constants.Image.placeholder)
        )
    }

    // MARK: - Вёрстка

    /// Подгоняет frame градиента под актуальные bounds картинки после layout pass.
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = remoteImageView.imageContentView.bounds
    }

    /// Сбрасывает загрузку изображения и градиент перед повторным использованием ячейки.
    override func prepareForReuse() {
        super.prepareForReuse()
        remoteImageView.prepareForReuse()
        gradientLayer.isHidden = true
    }
}

// MARK: - Настройка

private extension NewsCell {
    func setup() {
        contentView.backgroundColor = .adSurface
        contentView.layer.cornerRadius = Constants.Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        remoteImageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(Constants.Layout.gradientEndAlpha).cgColor
        ]
        gradientLayer.locations = [
            Constants.Layout.gradientStartLocation,
            Constants.Layout.gradientEndLocation
        ]
        remoteImageView.imageContentView.layer.addSublayer(gradientLayer)

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

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = Constants.Layout.textStackSpacing
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(remoteImageView)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(textStack)

        let padding = Constants.Layout.contentPadding
        let categoryEdge = Constants.Layout.categoryEdge
        NSLayoutConstraint.activate([
            remoteImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            remoteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            remoteImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            remoteImageView.heightAnchor.constraint(
                equalTo: remoteImageView.widthAnchor,
                multiplier: Constants.Image.aspectRatio
            ),

            categoryLabel.leadingAnchor.constraint(equalTo: remoteImageView.leadingAnchor, constant: categoryEdge),
            categoryLabel.bottomAnchor.constraint(equalTo: remoteImageView.bottomAnchor, constant: -categoryEdge),
            categoryLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: remoteImageView.trailingAnchor,
                constant: -categoryEdge
            ),

            textStack.topAnchor.constraint(
                equalTo: remoteImageView.bottomAnchor,
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

    /// Рисует текст с внутренними отступами — для чипа категории на превью.
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    /// Учитывает textInsets при расчёте размера, чтобы Auto Layout корректно лейаутил чип.
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
