import SwiftUI

struct WatermarkSettings {
    var dateFormat: String
    var fontName: String
    var fontSize: CGFloat
    var textColor: NSColor
    var position: CGPoint
    var shadowEnabled: Bool
    
    static let `default` = WatermarkSettings(
        dateFormat: "yyyy-MM-dd",
        fontName: "Digital Display",
        fontSize: 0.04,
        textColor: NSColor(red: 0.745, green: 0.529, blue: 0.314, alpha: 1.0),
        position: CGPoint(x: 0.95, y: 0.01),
        shadowEnabled: false
    )
} 