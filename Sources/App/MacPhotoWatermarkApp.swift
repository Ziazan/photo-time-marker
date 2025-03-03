import SwiftUI
import CoreText
import CoreGraphics

@main
struct MacPhotoWatermarkApp: App {
    init() {
        // 注册自定义字体
        if let fontURL = Bundle.module.url(forResource: "digital", withExtension: "ttf", subdirectory: "Resources/Fonts") {
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            if let error = error?.takeRetainedValue() {
                print("字体注册错误: \(error)")
            } else {
                print("字体注册成功")
                
                // 打印可用字体名称以确认正确的字体名
                let fontNames = CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
                print("可用字体家族: \(fontNames)")
            }
        } else {
            print("未找到字体文件")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        // 如果需要固定窗口大小，可以添加：
        // .windowResizability(.contentSize)
    }
} 