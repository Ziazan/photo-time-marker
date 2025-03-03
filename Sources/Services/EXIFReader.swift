import Foundation
import ImageIO
import UniformTypeIdentifiers

class EXIFReader {
    func getCreationDate(from url: URL) async throws -> Date? {
        // 首先尝试从 EXIF 获取日期
        if let exifDate = try? await readEXIFDate(from: url) {
            return exifDate
        }
        
        // 如果没有 EXIF 日期，尝试获取文件创建日期
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let creationDate = fileAttributes[.creationDate] as? Date {
            return creationDate
        }
        
        // 如果都没有，返回 nil 而不是当前日期
        return nil
    }
    
    private func readEXIFDate(from url: URL) async throws -> Date? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let exif = properties["{Exif}"] as? [String: Any] else {
            return nil
        }
        
        // 尝试不同的 EXIF 日期标签
        let dateStrings: [(String, String?)] = [
            ("DateTimeOriginal", exif["DateTimeOriginal"] as? String),
            ("DateTimeDigitized", exif["DateTimeDigitized"] as? String),
            ("DateTime", properties["DateTime"] as? String)
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // 尝试不同的日期格式
        let dateFormats = [
            "yyyy:MM:dd HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy:MM:dd"
        ]
        
        for (_, dateString) in dateStrings {
            guard let dateStr = dateString else { continue }
            
            for format in dateFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    enum EXIFError: Error {
        case noDateFound
        case invalidDateFormat
    }
} 