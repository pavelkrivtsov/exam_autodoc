import UIKit

private enum NewsDetailContentConstants {
    enum Text {
        static let readMore = "Читать полностью"
        static let metaSeparator = "  ·  "
    }

    enum Icon {
        static let safari = "safari"
    }

    enum Layout {
        static let stackSpacing: CGFloat = 16
        static let contentLeading: CGFloat = 20
        static let contentTrailing: CGFloat = 20
        static let contentBottom: CGFloat = 32
        static let preferredContentWidth: CGFloat = 720

        static let heroCornerRadius: CGFloat = 16
        static let heroAspectRatio: CGFloat = 0.6
        static let spacingAfterHero: CGFloat = 20

        static let spacingBeforeButton: CGFloat = 24
        static let metaFontSize: CGFloat = 12
        static let buttonImagePadding: CGFloat = 8
    }
}

extension NewsDetailViewController {
    /// Собирает scroll + stack и блоки контента - единая точка сборки экрана.
    func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = NewsDetailContentConstants.Layout.stackSpacing
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: NewsDetailContentConstants.Layout.contentLeading,
            bottom: NewsDetailContentConstants.Layout.contentBottom,
            trailing: NewsDetailContentConstants.Layout.contentTrailing
        )
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Ограничиваем ширину контента для удобного чтения на широком iPad,
        // при этом на узком iPhone контент занимает всю ширину.
        let preferredWidth = contentStack.widthAnchor.constraint(
            equalToConstant: NewsDetailContentConstants.Layout.preferredContentWidth
        )
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStack.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
            // Фиксируем ширину контента по видимой области — без горизонтального скролла.
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            preferredWidth
        ])

        addHeroIfNeeded()
        addTextBlocks()
        addReadMoreButtonIfNeeded()
    }

    /// Добавляет hero, если есть URL картинки - блок не нужен для текстовых новостей.
    func addHeroIfNeeded() {
        guard item.imageURL != nil else { return }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .adSurface
        container.layer.cornerRadius = NewsDetailContentConstants.Layout.heroCornerRadius
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleToFill
        heroImageView.clipsToBounds = true
        container.addSubview(heroImageView)

        heroSpinner.translatesAutoresizingMaskIntoConstraints = false
        heroSpinner.startAnimating()
        container.addSubview(heroSpinner)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: container.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(
                equalTo: container.widthAnchor,
                multiplier: NewsDetailContentConstants.Layout.heroAspectRatio
            ),
            heroSpinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            heroSpinner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        contentStack.addArrangedSubview(container)
        contentStack.setCustomSpacing(NewsDetailContentConstants.Layout.spacingAfterHero, after: container)
    }

    /// Добавляет мету, заголовок и описание - основной текстовый контент новости.
    func addTextBlocks() {
        var metaText = item.categoryType
        if let date = item.publishedDate {
            let dateString = DateDisplay.string(from: date)
            metaText = metaText.isEmpty
                ? dateString
                : "\(metaText)\(NewsDetailContentConstants.Text.metaSeparator)\(dateString)"
        }
        if !metaText.isEmpty {
            let metaLabel = UILabel()
            metaLabel.text = metaText.uppercased()
            metaLabel.font = .systemFont(ofSize: NewsDetailContentConstants.Layout.metaFontSize, weight: .semibold)
            metaLabel.textColor = .adBrand
            metaLabel.numberOfLines = 0
            contentStack.addArrangedSubview(metaLabel)
        }

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .adPrimaryText
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        if !item.description.isEmpty {
            let bodyLabel = UILabel()
            bodyLabel.text = item.description
            bodyLabel.font = .preferredFont(forTextStyle: .body)
            bodyLabel.adjustsFontForContentSizeCategory = true
            bodyLabel.textColor = .adPrimaryText
            bodyLabel.numberOfLines = 0
            contentStack.addArrangedSubview(bodyLabel)
        }
    }

    /// Добавляет кнопку «Читать полностью», если fullURL подходит для Safari.
    func addReadMoreButtonIfNeeded() {
        guard let url = item.fullURL, url.isSafariCompatible else { return }
        let config = UIButton.Configuration.adBrandProminent(
            title: NewsDetailContentConstants.Text.readMore,
            size: .large,
            image: UIImage(systemName: NewsDetailContentConstants.Icon.safari),
            imagePadding: NewsDetailContentConstants.Layout.buttonImagePadding,
            cornerStyle: .large
        )

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(openFullArticle), for: .touchUpInside)
        if let last = contentStack.arrangedSubviews.last {
            contentStack.setCustomSpacing(NewsDetailContentConstants.Layout.spacingBeforeButton, after: last)
        }
        contentStack.addArrangedSubview(button)
    }
}

