import SwiftUI
import UniformTypeIdentifiers
import Foundation

class MainViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var selectedPhoto: Photo?
    @Published var watermarkSettings = WatermarkSettings.default
    @Published var showSettings = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isShowingSettings = false
    
    private let imageProcessor = ImageProcessor()
    private let _progressManager = ProgressManager()
    let appSettings = AppSettings()
    
    var progressManager: ProgressManager { _progressManager }
    
    func handleDroppedFiles(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      self.isValidImageFile(url) else { return }
                
                DispatchQueue.main.async {
                    self.photos.append(Photo(originalURL: url))
                }
            }
        }
    }
    
    func processPhotos() {
        progressManager.start(totalItems: photos.count)
        
        Task {
            for (index, photo) in photos.enumerated() {
                guard photo.processingStatus == .pending else { continue }
                
                do {
                    try await imageProcessor.processPhoto(photo, 
                                                       with: appSettings.watermarkSettings,
                                                       outputDir: appSettings.outputDirectory)
                    await MainActor.run {
                        photos[index].processingStatus = .completed
                        progressManager.advance()
                    }
                } catch {
                    await MainActor.run {
                        photos[index].processingStatus = .failed
                        errorMessage = error.localizedDescription
                        showError = true
                        progressManager.advance()
                    }
                }
            }
            
            // 处理完成后通知用户
            await MainActor.run {
                NSSound.beep()
                if progressManager.currentItemIndex == photos.count {
                    showCompletionAlert()
                }
            }
        }
    }
    
    func processSelectedPhotos() {
        print("processSelectedPhotos 被调用")  // 添加调试输出
        
        // 如果没有选中照片，处理所有照片
        let photosToProcess = selectedPhoto != nil ? 
            [selectedPhoto!] : 
            photos.filter { $0.processingStatus != .completed }
        
        if photosToProcess.isEmpty {
            print("没有需要处理的照片")
            return
        }
        
        print("开始处理 \(photosToProcess.count) 张照片")
        
        Task {
            for photo in photosToProcess {
                do {
                    print("处理照片: \(photo.originalURL.lastPathComponent)")
                    try await imageProcessor.processPhoto(photo, 
                                                       with: appSettings.watermarkSettings,
                                                       outputDir: appSettings.outputDirectory)
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .completed
                            print("照片处理完成: \(photo.originalURL.lastPathComponent)")
                        }
                    }
                } catch {
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .failed
                            photos[index].error = error.localizedDescription
                            print("照片处理失败: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // 处理完成后通知用户
            await MainActor.run {
                NSSound.beep()
                showCompletionAlert()
            }
        }
    }
    
    private func showCompletionAlert() {
        let alert = NSAlert()
        alert.messageText = "处理完成"
        alert.informativeText = "所有照片已处理完成"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "打开输出文件夹")
        
        if alert.runModal() == .alertSecondButtonReturn {
            // 打开用户设置的输出文件夹，而不是默认目录
            NSWorkspace.shared.open(appSettings.outputDirectory)
        }
    }
    
    private func isValidImageFile(_ url: URL) -> Bool {
        let validExtensions = ["jpg", "jpeg", "png", "heic"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
    
    func clearPhotoList() {
        photos.removeAll()
        selectedPhoto = nil
    }
} 