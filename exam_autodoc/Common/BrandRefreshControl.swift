//
//  BrandRefreshControl.swift
//  exam_autodoc
//
//  Pull-to-refresh с круговым лоадером бренда вместо системного спиннера.
//

import UIKit

final class BrandRefreshControl: UIRefreshControl {

    private let loader = LoaderCircularView(size: .medium)

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
        loader.stopAnimating()
        super.endRefreshing()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isRefreshing {
            loader.startAnimating()
        }
    }
}
