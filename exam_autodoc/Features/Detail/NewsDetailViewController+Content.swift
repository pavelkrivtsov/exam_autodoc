import UIKit

private enum NewsDetailContentConstants {
    enum Text {
        static let readMore = "Читать полностью"
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

    enum Animation {
        static let imageFadeDuration: TimeInterval = 0.25
        static let fallbackScreenScale: CGFloat = 2
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
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            preferredWidth
        ])

        addHeroIfNeeded()
        addTextBlocks()
        addReadMoreButtonIfNeeded()
    }

    /// Загружает hero после layout — размер известен из constraints.
    func loadHeroImageIfNeeded() {
        guard viewModel.hasHeroImage else { return }
        let size = heroImageView.bounds.size
        heroImageView.setImage(
            url: viewModel.imageURL,
            targetSize: size,
            scale: view.adEffectiveScreenScale(
                fallback: NewsDetailContentConstants.Animation.fallbackScreenScale
            ),
            fadeDuration: NewsDetailContentConstants.Animation.imageFadeDuration
        )
    }

    func addHeroIfNeeded() {
        guard viewModel.hasHeroImage else { return }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .adSurface
        container.layer.cornerRadius = NewsDetailContentConstants.Layout.heroCornerRadius
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(heroImageView)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: container.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(
                equalTo: container.widthAnchor,
                multiplier: NewsDetailContentConstants.Layout.heroAspectRatio
            )
        ])

        contentStack.addArrangedSubview(container)
        contentStack.setCustomSpacing(NewsDetailContentConstants.Layout.spacingAfterHero, after: container)
    }

    func addTextBlocks() {
        if viewModel.hasMeta {
            let metaLabel = UILabel()
            metaLabel.text = viewModel.metaText.uppercased()
            metaLabel.font = .systemFont(
                ofSize: NewsDetailContentConstants.Layout.metaFontSize,
                weight: .semibold
            )
            metaLabel.textColor = .adBrand
            metaLabel.numberOfLines = 0
            contentStack.addArrangedSubview(metaLabel)
        }

        let titleLabel = UILabel()
        titleLabel.text = viewModel.title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .adPrimaryText
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        if viewModel.hasDescription {
            let bodyLabel = UILabel()
            bodyLabel.text = viewModel.description
            bodyLabel.font = .preferredFont(forTextStyle: .body)
            bodyLabel.adjustsFontForContentSizeCategory = true
            bodyLabel.textColor = .adPrimaryText
            bodyLabel.numberOfLines = 0
            contentStack.addArrangedSubview(bodyLabel)
        }
    }

    func addReadMoreButtonIfNeeded() {
        guard viewModel.articleURL != nil else { return }
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
            contentStack.setCustomSpacing(
                NewsDetailContentConstants.Layout.spacingBeforeButton,
                after: last
            )
        }
        contentStack.addArrangedSubview(button)
    }
}
