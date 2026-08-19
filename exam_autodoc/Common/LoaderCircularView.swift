//
//  LoaderCircularView.swift
//  exam_autodoc
//
//  Круговой лоадер: дуга с угловым градиентом (прозрачный → цвет бренда) и вращением.
//

import UIKit

private enum Constants {
    enum Text {
        static let accessibilityLabel = "Загрузка"
    }

    enum Animation {
        static let defaultProgress: CGFloat = 0.75
        static let duration: CFTimeInterval = 0.9
        static let key = "loader.rotation"
        static let keyPath = "transform.rotation.z"
    }

    enum Gradient {
        static let midAlpha: CGFloat = 0.35
        static let locations: [NSNumber] = [0, 0.55, 1]
    }

    enum SizeValue {
        static let smallSide: CGFloat = 24
        static let mediumSide: CGFloat = 40
        static let smallLineWidth: CGFloat = 2
        static let mediumLineWidth: CGFloat = 4
    }
}

/// Размер лоадера под место в UI.
enum LoaderCircularSize {
    /// Компактный - ячейки, футер, refresh.
    case small
    /// Крупнее - заглушка ленты.
    case medium

    var side: CGFloat {
        switch self {
        case .small: return Constants.SizeValue.smallSide
        case .medium: return Constants.SizeValue.mediumSide
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .small: return Constants.SizeValue.smallLineWidth
        case .medium: return Constants.SizeValue.mediumLineWidth
        }
    }
}

final class LoaderCircularView: UIView {

    /// Доля дуги (0…1), как `progress` в SwiftUI-версии.
    var progress: CGFloat = Constants.Animation.defaultProgress {
        didSet {
            let clamped = min(max(progress, 0), 1)
            if clamped != progress {
                progress = clamped
                return
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            shapeLayer.strokeEnd = progress
            CATransaction.commit()
        }
    }

    var color: UIColor = .adBrand {
        didSet { updateGradientColors() }
    }

    /// Как у `UIActivityIndicatorView`: скрывать, когда анимация остановлена.
    var hidesWhenStopped = true

    private let size: LoaderCircularSize
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    private var isAnimating = false

    init(size: LoaderCircularSize = .small, color: UIColor = .adBrand) {
        self.size = size
        self.color = color
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size.side, height: size.side)))
        isAccessibilityElement = true
        accessibilityLabel = Constants.Text.accessibilityLabel
        setupLayers()
        if hidesWhenStopped {
            isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Фиксированный размер view под выбранный preset (.small / .medium).
    override var intrinsicContentSize: CGSize {
        CGSize(width: size.side, height: size.side)
    }

    /// Обновляет path дуги и frame слоёв при изменении bounds (rotation, layout).
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        shapeLayer.frame = bounds
        shapeLayer.path = makePath().cgPath
        shapeLayer.lineWidth = size.lineWidth
        shapeLayer.strokeEnd = progress
    }

    /// Возобновляет вращение после возврата во view hierarchy (например, при reuse ячейки).
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if isAnimating, window != nil {
            addRotationAnimation()
        }
    }

    // MARK: - Управление

    func startAnimating() {
        isHidden = false
        if progress < Constants.Animation.defaultProgress {
            progress = Constants.Animation.defaultProgress
        }
        guard !isAnimating else { return }
        isAnimating = true
        addRotationAnimation()
    }

    func stopAnimating() {
        isAnimating = false
        layer.removeAnimation(forKey: Constants.Animation.key)
        layer.transform = CATransform3DIdentity
        if hidesWhenStopped {
            isHidden = true
        }
    }
}

// MARK: - Слои

private extension LoaderCircularView {
    func setupLayers() {
        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        updateGradientColors()

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = progress

        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }

    func updateGradientColors() {
        // Нельзя использовать `.clear` (0,0,0,0) — в коническом градиенте
        // RGB интерполируется через чёрный и даёт тёмные участки.
        // Берём тот же hue с нулевой альфой.
        let transparentBrand = color.withAlphaComponent(0)
        gradientLayer.colors = [
            transparentBrand.cgColor,
            color.withAlphaComponent(Constants.Gradient.midAlpha).cgColor,
            color.cgColor
        ]
        gradientLayer.locations = Constants.Gradient.locations
    }

    func makePath() -> UIBezierPath {
        let inset = size.lineWidth / 2
        return UIBezierPath(
            ovalIn: bounds.insetBy(dx: inset, dy: inset)
        )
    }

    func addRotationAnimation() {
        layer.removeAnimation(forKey: Constants.Animation.key)
        let animation = CABasicAnimation(keyPath: Constants.Animation.keyPath)
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = Constants.Animation.duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(animation, forKey: Constants.Animation.key)
    }
}
