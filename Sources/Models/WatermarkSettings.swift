import SwiftUI

struct WatermarkSettings: Codable {
    var dateFormat: String
    var fontName: String
    var fontSize: CGFloat
    var position: CGPoint
    var textColor: ColorComponents
    var outputDirectory: URL
    
    static var `default`: WatermarkSettings {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let defaultOutputDir = documentsDirectory.appendingPathComponent("MacPhotoWatermark")
        
        return WatermarkSettings(
            dateFormat: "yyyy-MM-dd",
            fontName: "Digital Display",
            fontSize: 0.04,  // 相对于图片较短边的比例
            position: CGPoint(x: 0.85, y: 0.95),  // 右下角
            textColor: ColorComponents(
                redComponent: 0.745,
                greenComponent: 0.529,
                blueComponent: 0.314,
                alphaComponent: 1
            ),
            outputDirectory: defaultOutputDir
        )
    }
}

struct ColorComponents: Codable {
    var redComponent: Double
    var greenComponent: Double
    var blueComponent: Double
    var alphaComponent: Double
} 