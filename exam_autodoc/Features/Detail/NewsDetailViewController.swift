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

    let item: NewsItem
    let toast = ToastBannerView()

    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let heroImageView = UIImageView()
    let heroSpinner = LoaderCircularView(size: .small)

    var imageTask: Task<Void, Never>?
    var didRequestImage = false

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

    // MARK: - Lifecycle

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
