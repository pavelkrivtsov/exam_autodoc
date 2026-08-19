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

    let viewModel: NewsDetailViewModel
    let toast = ToastBannerView()

    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let heroImageView = RemoteImageView()

    init(viewModel: NewsDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    /// Создаёт иерархию view программно и собирает scroll + контент новости.
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .adBackground
        view = root
        setup()
    }

    /// Первичная настройка после создания view: отключаем large title на экране детали.
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }

    /// После расчёта constraints известен реальный размер hero — запускаем загрузку картинки.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadHeroImageIfNeeded()
    }
}
