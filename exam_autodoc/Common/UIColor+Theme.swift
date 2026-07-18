//
//  UIColor+Theme.swift
//  exam_autodoc
//
//  Цвета бренда Autodoc из ассетов (светлая / тёмная тема).
//

import UIKit

extension UIColor {
    /// Акцент бренда (#DB151E / #E53935).
    static let adBrand = UIColor(named: "Brand") ?? .systemRed
    /// Фон экрана (#F4F5F7 / #000000).
    static let adBackground = UIColor(named: "Background") ?? .systemGroupedBackground
    /// Поверхность карточек (#FFFFFF / #1C1C1E).
    static let adSurface = UIColor(named: "Surface") ?? .secondarySystemGroupedBackground
    /// Основной текст (#000000 / #F5F5F7).
    static let adPrimaryText = UIColor(named: "PrimaryText") ?? .label
    /// Вторичный текст / даты (#7A7A7C / #A1A1A6).
    static let adSecondaryText = UIColor(named: "SecondaryText") ?? .secondaryLabel
    /// Третичный текст / мета (#8E8E93).
    static let adTertiaryText = UIColor(named: "TertiaryText") ?? .tertiaryLabel
    /// Разделители (#E5E5EA / #38383A).
    static let adSeparator = UIColor(named: "Separator") ?? .separator
    /// Фон плейсхолдера изображения (#2C2C2C / #1A1A1A).
    static let adPlaceholderBackground = UIColor(named: "PlaceholderBackground") ?? .darkGray
}
