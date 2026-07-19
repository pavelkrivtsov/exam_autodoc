//
//  ToastBannerView.swift
//  exam_autodoc
//
//  Короткий баннер-уведомление у верхнего края экрана.
//

import UIKit

final class ToastBannerView: UIView {

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let appearDuration: TimeInterval = 0.25
        static let visibleDuration: TimeInterval = 2.5
    }

    private let messageLabel = UILabel()
    private var hideWorkItem: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Показывает текст и через паузу скрывает баннер.
    func show(_ message: String, in host: UIView, below anchor: NSLayoutYAxisAnchor) {
        hideWorkItem?.cancel()
        messageLabel.text = message
        isHidden = false
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -8)

        if superview !== host {
            removeFromSuperview()
            translatesAutoresizingMaskIntoConstraints = false
            host.addSubview(self)
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: anchor, constant: Constants.horizontalInset),
                leadingAnchor.constraint(
                    equalTo: host.safeAreaLayoutGuide.leadingAnchor,
                    constant: Constants.horizontalInset
                ),
                trailingAnchor.constraint(
                    equalTo: host.safeAreaLayoutGuide.trailingAnchor,
                    constant: -Constants.horizontalInset
                )
            ])
        }
        host.bringSubviewToFront(self)

        UIView.animate(withDuration: Constants.appearDuration) {
            self.alpha = 1
            self.transform = .identity
        }

        let work = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.visibleDuration, execute: work)
    }

    private func dismiss() {
        UIView.animate(withDuration: Constants.appearDuration, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -8)
        }, completion: { _ in
            self.isHidden = true
        })
    }

    private func setup() {
        // Лёгкий системный жёлтый — предупреждение без агрессивного акцента.
        backgroundColor = UIColor.systemYellow.withAlphaComponent(0.35)
        layer.cornerRadius = Constants.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isHidden = true

        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: Constants.verticalPadding
            ),
            messageLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Constants.verticalPadding
            ),
            messageLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constants.horizontalPadding
            ),
            messageLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constants.horizontalPadding
            )
        ])
    }
}
