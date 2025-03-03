import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var outputDirectory: URL
    @Published var watermarkSettings: WatermarkSettings
    
    private let settingsKey = "appSettings"
    
    init() {
        // 默认值设置 - 使用 Pictures 目录而不是创建子目录
        let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        var initialOutputDir = picturesURL
        
        // 尝试从用户默认设置加载
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(SavedSettings.self, from: data) {
            
            // 解析书签（不使用 self.resolveBookmark 方法）
            if let bookmarkData = settings.outputDirectoryBookmark {
                do {
                    var isStale = false
                    let url = try URL(resolvingBookmarkData: bookmarkData, 
                                    options: .withSecurityScope, 
                                    relativeTo: nil, 
                                    bookmarkDataIsStale: &isStale)
                    
                    if !isStale {
                        initialOutputDir = url
                    }
                } catch {
                    print("解析书签失败: \(error)")
                }
            }
        }
        
        // 先初始化所有属性
        self.outputDirectory = initialOutputDir
        self.watermarkSettings = WatermarkSettings.default
        
        // 确保输出目录存在，这已经在所有属性初始化后发生
        try? FileManager.default.createDirectory(at: outputDirectory, 
                                              withIntermediateDirectories: true, 
                                              attributes: nil)
    }
    
    private func saveSettings() {
        do {
            // 创建安全书签，确保应用能在重启后访问选择的目录
            let bookmarkData = try outputDirectory.bookmarkData(options: .withSecurityScope, 
                                                             includingResourceValuesForKeys: nil, 
                                                             relativeTo: nil)
            
            let savedSettings = SavedSettings(outputDirectoryBookmark: bookmarkData)
            let data = try JSONEncoder().encode(savedSettings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            print("保存设置失败: \(error)")
        }
    }
    
    private func resolveBookmark(_ bookmark: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark, 
                           options: .withSecurityScope, 
                           relativeTo: nil, 
                           bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("书签已过期，需要更新")
                return nil
            }
            
            return url
        } catch {
            print("解析书签失败: \(error)")
            return nil
        }
    }
    
    // 这个结构体用于编码/解码保存的设置
    private struct SavedSettings: Codable {
        let outputDirectoryBookmark: Data?
    }
} 