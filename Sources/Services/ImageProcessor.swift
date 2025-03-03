import SwiftUI
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import CoreServices  // 添加这行，用于 kUTTypeJPEG
import UniformTypeIdentifiers  // 添加这行

class ImageProcessor {
    private let context = CIContext()
    private let exifReader = EXIFReader()
    
    func processPhoto(_ photo: Photo, 
                    with settings: WatermarkSettings,
                    outputDir: URL) async throws {
        // 更新状态为处理中
        await MainActor.run {
            var updatedPhoto = photo
            updatedPhoto.processingStatus = .processing
        }
        
        guard let image = CIImage(contentsOf: photo.originalURL) else {
            throw ProcessError.invalidImage
        }
        
        // 读取EXIF信息
        let date = try await exifReader.getCreationDate(from: photo.originalURL)
        
        // 创建输出URL
        let outputURL = try createOutputURL(for: photo, in: outputDir)
        
        // 如果有日期，添加水印；否则直接保存原图
        let finalImage: CIImage
        if let date = date {
            // 创建水印
            finalImage = try addWatermark(to: image, 
                                        date: date,
                                        settings: settings)
        } else {
            print("未找到照片日期，跳过水印")
            finalImage = image
        }
        
        // 保存处理后的图片
        try save(finalImage, to: outputURL)
        
        // 更新照片状态
        await MainActor.run {
            var updatedPhoto = photo
            updatedPhoto.processedURL = outputURL
            updatedPhoto.processingStatus = .completed
        }
    }
    
    private func addWatermark(to image: CIImage, 
                            date: Date,
                            settings: WatermarkSettings) throws -> CIImage {
        let imageSize = image.extent.size
        
        // 首先将 CIImage 转换为 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw ProcessError.watermarkError
        }
        
        // 创建 Graphics Context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                    width: Int(imageSize.width),
                                    height: Int(imageSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw ProcessError.watermarkError
        }
        
        // 绘制原始图片
        let rect = CGRect(origin: .zero, size: imageSize)
        context.draw(cgImage, in: rect)
        
        // 设置文本绘制
        context.saveGState()
        
        // 绘制时间水印
        let dateFont = CTFontCreateWithName(settings.fontName as CFString,
                                          imageSize.height * settings.fontSize,
                                          nil)
        
        // 创建包含颜色的文本属性
        let color = settings.textColor
        let colorRef = CGColor(red: CGFloat(color.redComponent),
                             green: CGFloat(color.greenComponent),
                             blue: CGFloat(color.blueComponent),
                             alpha: CGFloat(color.alphaComponent))
        
        // 包含字体和颜色的属性字典
        let dateAttrs = [
            kCTFontAttributeName: dateFont,
            kCTForegroundColorAttributeName: colorRef
        ] as CFDictionary
        
        let formatter = DateFormatter()
        formatter.dateFormat = settings.dateFormat
        let dateText = formatter.string(from: date) as CFString
        
        let dateLine = CTLineCreateWithAttributedString(
            CFAttributedStringCreate(nil, dateText, dateAttrs)!
        )
        
        let dateBounds = CTLineGetBoundsWithOptions(dateLine, .useOpticalBounds)
        let dateX = imageSize.width * settings.position.x - dateBounds.width  // 右对齐
        let dateY = imageSize.height * settings.position.y + dateBounds.height  // 从底部计算，加上文本高度
        
        // 绘制时间水印
        context.textPosition = CGPoint(x: dateX, y: dateY)
        CTLineDraw(dateLine, context)
        
        context.restoreGState()
        
        // 获取结果图片
        guard let resultCGImage = context.makeImage() else {
            throw ProcessError.watermarkError
        }
        
        // 转换回 CIImage
        return CIImage(cgImage: resultCGImage)
    }
    
    private func createOutputURL(for photo: Photo, in directory: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // 确保输出目录存在
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, 
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        }
        
        // 创建更有意义的输出文件名
        let fileName = photo.originalURL.deletingPathExtension().lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        // 使用原文件名+时间戳作为新文件名
        let outputURL = directory.appendingPathComponent("\(fileName)_\(timestamp).jpg")
        
        return outputURL
    }
    
    private func save(_ image: CIImage, to url: URL) throws {
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw ProcessError.saveError
        }
        
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessError.saveError
        }
        
        let options = [
            kCGImageDestinationLossyCompressionQuality: 0.9
        ] as CFDictionary
        
        CGImageDestinationAddImage(destination, cgImage, options)
        
        if !CGImageDestinationFinalize(destination) {
            throw ProcessError.saveError
        }
    }
    
    enum ProcessError: Error, LocalizedError {
        case invalidImage
        case watermarkError
        case saveError
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "无法读取图片"
            case .watermarkError:
                return "添加水印失败"
            case .saveError:
                return "保存图片失败"
            }
        }
    }
} 