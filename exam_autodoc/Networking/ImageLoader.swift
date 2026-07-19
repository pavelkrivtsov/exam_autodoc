//
//  ImageLoader.swift
//  exam_autodoc
//
//  Лёгкий асинхронный загрузчик изображений: кэш в памяти, дедупликация запросов
//  и даунсэмплинг через ImageIO. Даунсэмплинг держит потребление памяти стабильным
//  независимо от разрешения исходника — важно для плавного скролла на iPad.
//

import UIKit
import ImageIO

actor ImageLoader {

    private enum Constants {
        static let requestTimeout: TimeInterval = 20
        static let memoryCacheLimit = 300
        static let urlCacheMemoryCapacity = 32 * 1024 * 1024
        static let urlCacheDiskCapacity = 256 * 1024 * 1024
        static let minPixelSize: CGFloat = 1
    }

    /// Единый загрузчик для всего приложения - чтобы экраны делили кэш и in-flight задачи.
    static let shared = ImageLoader()

    private let session: URLSession
    private let cache = NSCache<NSString, UIImage>()
    private var inFlight: [NSString: Task<UIImage, any Error>] = [:]

    /// Создаёт загрузчик с переданным или собственным URLSession - свой session нужен для дискового кэша и таймаутов.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .returnCacheDataElseLoad
            configuration.timeoutIntervalForRequest = Constants.requestTimeout
            configuration.urlCache = URLCache(
                memoryCapacity: Constants.urlCacheMemoryCapacity,
                diskCapacity: Constants.urlCacheDiskCapacity
            )
            self.session = URLSession(configuration: configuration)
        }
        cache.countLimit = Constants.memoryCacheLimit
    }

    /// Загружает и возвращает изображение под `targetSize` (points), с кэшем и дедупликацией - чтобы не качать одно и то же и не раздувать память при скролле.
    func image(for url: URL, targetSize: CGSize, scale: CGFloat) async throws -> UIImage {
        let maxPixel = max(targetSize.width, targetSize.height) * scale
        let key = "\(url.absoluteString)|\(Int(maxPixel))" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }
        if let task = inFlight[key] {
            return try await task.value
        }

        let task = Task<UIImage, any Error> { [session] in
            let (data, _) = try await session.data(from: url)
            guard let image = ImageLoader.downsample(data: data, maxPixel: maxPixel) else {
                throw NewsServiceError.invalidResponse
            }
            return image
        }
        inFlight[key] = task

        do {
            let image = try await task.value
            cache.setObject(image, forKey: key)
            inFlight[key] = nil
            return image
        } catch {
            inFlight[key] = nil
            throw error
        }
    }

    /// Уменьшает изображение через ImageIO до `maxPixel` по длинной стороне - полный bitmap в память не попадает.
    private static func downsample(data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixel, Constants.minPixelSize)
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
