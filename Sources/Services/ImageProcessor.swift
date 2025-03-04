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
                    outputDir: URL,
                    progressHandler: @escaping (Double) -> Void) async throws {
        // 更新状态为处理中
        await MainActor.run {
            progressHandler(0.1)  // 开始处理
        }
        
        guard let image = CIImage(contentsOf: photo.originalURL) else {
            throw ProcessError.invalidImage
        }
        
        await MainActor.run {
            progressHandler(0.3)  // 加载图片完成
        }
        
        // 读取EXIF信息
        let date = try await exifReader.getCreationDate(from: photo.originalURL)
        
        await MainActor.run {
            progressHandler(0.5)  // EXIF读取完成
        }
        
        // 创建输出URL
        let outputURL = try createOutputURL(for: photo, in: outputDir)
        
        // 如果有日期，添加水印；否则直接保存原图
        let finalImage: CIImage
        if let date = date {
            // 创建水印
            finalImage = try addWatermark(to: image, 
                                        date: date,
                                        settings: settings,
                                        originalURL: photo.originalURL)
        } else {
            print("未找到照片日期，跳过水印")
            finalImage = image
        }
        
        await MainActor.run {
            progressHandler(0.8)  // 水印处理完成
        }
        
        // 保存处理后的图片
        try save(finalImage, to: outputURL, from: photo.originalURL)
        
        // 更新照片状态
        await MainActor.run {
            progressHandler(1.0)  // 处理完成
        }
    }
    
    private func addWatermark(to image: CIImage, 
                            date: Date,
                            settings: WatermarkSettings,
                            originalURL: URL) throws -> CIImage {
        let imageSize = image.extent.size
        
        // 首先将 CIImage 转换为 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw ProcessError.watermarkError
        }
        
        // 创建 NSImage 用于绘制
        let nsImage = NSImage(cgImage: cgImage, size: imageSize)
        
        // 在 NSImage 上绘制水印
        nsImage.lockFocus()
        
        // 设置文本属性
        let fontSize = min(imageSize.width, imageSize.height) * settings.fontSize
        let font = NSFont(name: settings.fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        
        let color = settings.textColor
        let nsColor = NSColor(red: CGFloat(color.redComponent),
                            green: CGFloat(color.greenComponent),
                            blue: CGFloat(color.blueComponent),
                            alpha: CGFloat(color.alphaComponent))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // 格式化日期
        let formatter = DateFormatter()
        formatter.dateFormat = settings.dateFormat
        let dateString = formatter.string(from: date)
        
        // 计算文本尺寸
        let textSize = dateString.size(withAttributes: attributes)
        
        // 计算水印位置
        let imageWidth = CGFloat(cgImage.width)
        
        // 使用绝对边距计算位置，注意在 macOS 中 Y 坐标是从底部向上增长的
        let x = imageWidth - settings.marginRight - textSize.width
        let y = settings.marginBottom // 直接使用底部边距作为 Y 坐标
        
        // 绘制文本
        dateString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
        
        nsImage.unlockFocus()
        
        // 将 NSImage 转换回 CIImage
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]),
              let ciImage = CIImage(data: jpegData) else {
            throw ProcessError.watermarkError
        }
        
        return ciImage
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
    
    private func save(_ image: CIImage, to url: URL, from originalURL: URL) throws {
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw ProcessError.saveError
        }
        
        // 根据原始文件扩展名确定输出类型
        let originalExtension = originalURL.pathExtension.lowercased()
        let typeIdentifier: String
        switch originalExtension {
        case "jpg", "jpeg":
            typeIdentifier = UTType.jpeg.identifier
        case "png":
            typeIdentifier = UTType.png.identifier
        case "heic":
            typeIdentifier = UTType.heic.identifier
        default:
            typeIdentifier = UTType.jpeg.identifier
        }
        
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            typeIdentifier as CFString,
            1,
            nil
        ) else {
            throw ProcessError.saveError
        }
        
        // 复制原始图片的属性，包括方向信息
        if let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) {
            // 完全保持原始属性，不修改任何内容
            CGImageDestinationAddImage(destination, cgImage, properties)
        } else {
            // 如果无法获取原始属性，使用默认设置
            let options = [
                kCGImageDestinationLossyCompressionQuality: 1.0
            ] as CFDictionary
            
            CGImageDestinationAddImage(destination, cgImage, options)
        }
        
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

// 添加扩展来获取图片类型
extension Data {
    var imageType: CIFormat {
        let header = self.prefix(3).map { UInt8($0) }
        switch header {
        case [0xFF, 0xD8, 0xFF]:  // JPEG header
            return .RGBA8
        case [0x89, 0x50, 0x4E]:  // PNG header
            return .RGBA16
        default:
            return .RGBA8  // 默认使用 JPEG
        }
    }
} 