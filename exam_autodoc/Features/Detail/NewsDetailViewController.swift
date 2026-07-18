//
//  NewsDetailViewController.swift
//  exam_autodoc
//
//  Экран полной новости: изображение, мета, описание и кнопка открытия
//  полной статьи во встроенном Safari (SafariServices, без сторонних библиотек).
//

import UIKit
import SafariServices

final class NewsDetailViewController: UIViewController {

    private let item: NewsItem

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImageView = UIImageView()
    private let heroSpinner = UIActivityIndicatorView(style: .medium)

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadHeroImageIfNeeded()
    }

    // MARK: - Настройка

    private func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 20, bottom: 32, trailing: 20
        )
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Ограничиваем ширину контента для удобного чтения на широком iPad,
        // при этом на узком iPhone контент занимает всю ширину.
        let preferredWidth = contentStack.widthAnchor.constraint(equalToConstant: 720)
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

    private func addHeroIfNeeded() {
        guard item.imageURL != nil else { return }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleAspectFill
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
            container.heightAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.6),
            heroSpinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            heroSpinner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        contentStack.addArrangedSubview(container)
        contentStack.setCustomSpacing(20, after: container)
    }

    private func addTextBlocks() {
        var metaText = item.categoryType
        if let date = item.publishedDate {
            let dateString = DateDisplay.string(from: date)
            metaText = metaText.isEmpty ? dateString : "\(metaText)  ·  \(dateString)"
        }
        if !metaText.isEmpty {
            let metaLabel = UILabel()
            metaLabel.text = metaText.uppercased()
            metaLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            metaLabel.textColor = .systemBlue
            metaLabel.numberOfLines = 0
            contentStack.addArrangedSubview(metaLabel)
        }

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        if !item.description.isEmpty {
            let bodyLabel = UILabel()
            bodyLabel.text = item.description
            bodyLabel.font = .preferredFont(forTextStyle: .body)
            bodyLabel.adjustsFontForContentSizeCategory = true
            bodyLabel.textColor = .label
            bodyLabel.numberOfLines = 0
            contentStack.addArrangedSubview(bodyLabel)
        }
    }

    private func addReadMoreButtonIfNeeded() {
        guard item.fullURL != nil else { return }
        var config = UIButton.Configuration.borderedProminent()
        config.title = "Читать полностью"
        config.image = UIImage(systemName: "safari")
        config.imagePadding = 8
        config.cornerStyle = .large
        config.buttonSize = .large

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(openFullArticle), for: .touchUpInside)
        if let last = contentStack.arrangedSubviews.last {
            contentStack.setCustomSpacing(24, after: last)
        }
        contentStack.addArrangedSubview(button)
    }

    // MARK: - Изображение

    private func loadHeroImageIfNeeded() {
        guard let url = item.imageURL, !didRequestImage else { return }
        let size = heroImageView.bounds.size
        guard size.width > 1, size.height > 1 else { return }
        didRequestImage = true

        let scale = view.window?.screen.scale ?? traitCollection.displayScale
        let effectiveScale = scale > 0 ? scale : 2
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.image(for: url, targetSize: size, scale: effectiveScale)
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
                UIView.transition(with: self.heroImageView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.heroImageView.image = image
                }
            } catch {
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
            }
        }
    }

    // MARK: - Действия

    @objc private func openFullArticle() {
        guard let url = item.fullURL else { return }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
}
