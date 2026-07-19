//
//  BrandRefreshControl.swift
//  exam_autodoc
//
//  Pull-to-refresh: лоадер бренда во время запроса, баннер при ошибке,
//  без лишнего UI при успехе.
//

import UIKit

final class BrandRefreshControl: UIRefreshControl {

    private let loader = LoaderCircularView(size: .medium)
    private let toast = ToastBannerView()

    override init() {
        super.init()
        // Прячем системный индикатор — показываем свой.
        tintColor = .clear
        loader.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func beginRefreshing() {
        super.beginRefreshing()
        loader.startAnimating()
    }

    override func endRefreshing() {
        finish(failureMessage: nil)
    }

    /// Завершает refresh: при `failureMessage` показывает баннер, иначе только прячет лоадер.
    func finish(failureMessage: String? = nil) {
        loader.stopAnimating()
        if isRefreshing {
            super.endRefreshing()
        }
        if let failureMessage {
            presentToast(failureMessage)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isRefreshing {
            loader.startAnimating()
        }
    }

    /// Баннер вешаем на контейнер экрана (superview collection view), не на сам refresh.
    private func presentToast(_ message: String) {
        guard let host = superview?.superview else { return }
        toast.show(message, in: host, below: host.safeAreaLayoutGuide.topAnchor)
    }
}
