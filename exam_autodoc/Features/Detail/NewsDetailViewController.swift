//
//  NewsDetailViewController.swift
//  exam_autodoc
//
//  Экран полной новости: изображение, мета, описание и кнопка открытия
//  полной статьи во встроенном Safari (SafariServices, без сторонних библиотек).
//

import UIKit
import SafariServices

private enum Constants {
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
        static let minImageDimension: CGFloat = 1
    }

    enum Animation {
        static let imageFadeDuration: TimeInterval = 0.25
        static let fallbackScreenScale: CGFloat = 2
    }
}

final class NewsDetailViewController: UIViewController {

    private let item: NewsItem

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImageView = UIImageView()
    private let heroSpinner = LoaderCircularView(size: .small)

    private var imageTask: Task<Void, Never>?
    private var didRequestImage = false

    init(item: NewsItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageTask?.cancel()
    }

    //     MARK: - Lifecycle
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .adBackground
        view = root
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadHeroImageIfNeeded()
    }
}

// MARK: - Настройка
private extension NewsDetailViewController {
    /// Собирает scroll + stack и блоки контента - единая точка сборки экрана.
    func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = Constants.Layout.stackSpacing
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: Constants.Layout.contentLeading,
            bottom: Constants.Layout.contentBottom,
            trailing: Constants.Layout.contentTrailing
        )
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Ограничиваем ширину контента для удобного чтения на широком iPad,
        // при этом на узком iPhone контент занимает всю ширину.
        let preferredWidth = contentStack.widthAnchor.constraint(
            equalToConstant: Constants.Layout.preferredContentWidth
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
        container.layer.cornerRadius = Constants.Layout.heroCornerRadius
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
                multiplier: Constants.Layout.heroAspectRatio
            ),
            heroSpinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            heroSpinner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        contentStack.addArrangedSubview(container)
        contentStack.setCustomSpacing(Constants.Layout.spacingAfterHero, after: container)
    }

    /// Добавляет мету, заголовок и описание - основной текстовый контент новости.
    func addTextBlocks() {
        var metaText = item.categoryType
        if let date = item.publishedDate {
            let dateString = DateDisplay.string(from: date)
            metaText = metaText.isEmpty
                ? dateString
                : "\(metaText)\(Constants.Text.metaSeparator)\(dateString)"
        }
        if !metaText.isEmpty {
            let metaLabel = UILabel()
            metaLabel.text = metaText.uppercased()
            metaLabel.font = .systemFont(ofSize: Constants.Layout.metaFontSize, weight: .semibold)
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

    /// Добавляет кнопку «Читать полностью», если есть fullURL - открытие статьи во встроенном Safari.
    func addReadMoreButtonIfNeeded() {
        guard item.fullURL != nil else { return }
        let config = UIButton.Configuration.adBrandProminent(
            title: Constants.Text.readMore,
            size: .large,
            image: UIImage(systemName: Constants.Icon.safari),
            imagePadding: Constants.Layout.buttonImagePadding,
            cornerStyle: .large
        )

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(openFullArticle), for: .touchUpInside)
        if let last = contentStack.arrangedSubviews.last {
            contentStack.setCustomSpacing(Constants.Layout.spacingBeforeButton, after: last)
        }
        contentStack.addArrangedSubview(button)
    }

    // MARK: - Изображение

    /// Загружает hero после первого layout - нужен реальный размер для даунсэмплинга.
    func loadHeroImageIfNeeded() {
        guard let url = item.imageURL, !didRequestImage else { return }
        let size = heroImageView.bounds.size
        guard size.width > Constants.Layout.minImageDimension,
              size.height > Constants.Layout.minImageDimension else { return }
        didRequestImage = true

        let effectiveScale = view.adEffectiveScreenScale(fallback: Constants.Animation.fallbackScreenScale)
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.image(for: url, targetSize: size, scale: effectiveScale)
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
                self.heroImageView.setImage(image, fadedWith: Constants.Animation.imageFadeDuration)
            } catch {
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
            }
        }
    }

    // MARK: - Действия

    /// Открывает fullURL во встроенном Safari - без ухода в сторонний браузер.
    @objc func openFullArticle() {
        guard let url = item.fullURL else { return }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
}
