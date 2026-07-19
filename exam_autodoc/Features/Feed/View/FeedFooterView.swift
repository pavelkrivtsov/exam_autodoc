//
//  FeedFooterView.swift
//  exam_autodoc
//
//  Футер секции со спиннером во время загрузки следующей страницы.
//

import UIKit

final class FeedFooterView: UICollectionReusableView {
    static let reuseID = "FeedFooterView"

    private let spinner = LoaderCircularView(size: .small)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ loading: Bool) {
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }
}
