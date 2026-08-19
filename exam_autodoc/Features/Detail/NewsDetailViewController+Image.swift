import UIKit

private enum NewsDetailImageConstants {
    enum Layout {
        static let minImageDimension: CGFloat = 1
    }

    enum Animation {
        static let imageFadeDuration: TimeInterval = 0.25
        static let fallbackScreenScale: CGFloat = 2
    }
}

extension NewsDetailViewController {
    /// Загружает hero после первого layout - нужен реальный размер для даунсэмплинга.
    func loadHeroImageIfNeeded() {
        guard let url = item.imageURL, !didRequestImage else { return }
        let size = heroImageView.bounds.size
        guard size.width > NewsDetailImageConstants.Layout.minImageDimension,
              size.height > NewsDetailImageConstants.Layout.minImageDimension else { return }
        didRequestImage = true

        let effectiveScale = view.adEffectiveScreenScale(
            fallback: NewsDetailImageConstants.Animation.fallbackScreenScale
        )
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.image(
                    for: url,
                    targetSize: size,
                    scale: effectiveScale
                )
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
                self.heroImageView.setImage(
                    image,
                    fadedWith: NewsDetailImageConstants.Animation.imageFadeDuration
                )
            } catch {
                if Task.isCancelled { return }
                self.heroSpinner.stopAnimating()
            }
        }
    }
}

