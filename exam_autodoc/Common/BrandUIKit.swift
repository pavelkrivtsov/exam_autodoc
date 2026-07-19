//
//  BrandUIKit.swift
//  exam_autodoc
//
//  Общие UI-хелперы бренда: тексты, кнопки, fade картинок, scale экрана.
//

import UIKit

/// Пользовательские строки, общие для нескольких экранов.
enum AppText {
    /// Кнопка повтора загрузки - stub ленты и футер пагинации.
    static let retry = "Повторить"
}

extension UIButton.Configuration {
    /// Prominent-кнопка в цвете бренда - единый вид CTA по приложению.
    static func adBrandProminent(
        title: String,
        size: UIButton.Configuration.Size = .medium,
        image: UIImage? = nil,
        imagePadding: CGFloat = 0,
        cornerStyle: UIButton.Configuration.CornerStyle = .dynamic
    ) -> UIButton.Configuration {
        var config = UIButton.Configuration.borderedProminent()
        config.title = title
        config.image = image
        config.imagePadding = imagePadding
        config.cornerStyle = cornerStyle
        config.buttonSize = size
        config.baseBackgroundColor = .adBrand
        config.baseForegroundColor = .white
        return config
    }
}

extension UIImageView {
    /// Ставит изображение с cross-dissolve - мягкая смена без мигания.
    func setImage(_ image: UIImage?, fadedWith duration: TimeInterval) {
        UIView.transition(
            with: self,
            duration: duration,
            options: .transitionCrossDissolve
        ) {
            self.image = image
        }
    }
}

extension UIView {
    /// Scale экрана с запасным значением - ImageLoader не получает нулевой scale.
    func adEffectiveScreenScale(fallback: CGFloat = 2) -> CGFloat {
        let scale = window?.screen.scale ?? traitCollection.displayScale
        return scale > 0 ? scale : fallback
    }
}
