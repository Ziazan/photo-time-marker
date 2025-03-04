import SwiftUI
import UniformTypeIdentifiers
import Foundation

class MainViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var selectedPhoto: Photo?
    @Published var watermarkSettings = WatermarkSettings.default
    @Published var showSettings = false
    @Published var errorMessage: ErrorMessage? = nil
    @Published var showError = false
    @Published var isShowingSettings = false
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    
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
                    // 更新状态为处理中
                    await MainActor.run {
                        photos[index].processingStatus = .processing
                        photos[index].progress = 0
                    }
                    
                    try await imageProcessor.processPhoto(
                        photo, 
                        with: appSettings.watermarkSettings,
                        outputDir: appSettings.outputDirectory,
                        progressHandler: { progress in
                            // 更新进度
                            DispatchQueue.main.async {
                                self.photos[index].progress = progress
                            }
                        }
                    )
                    
                    await MainActor.run {
                        photos[index].processingStatus = .completed
                        photos[index].progress = 1.0
                        progressManager.advance()
                    }
                } catch {
                    await MainActor.run {
                        photos[index].processingStatus = .failed
                        photos[index].progress = 0
                        errorMessage = ErrorMessage(message: error.localizedDescription)
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
        print("processSelectedPhotos 被调用")
        
        // 检查是否有选中的照片
        if selectedPhoto == nil {
            // 显示提示
            let alert = NSAlert()
            alert.messageText = "未选择照片"
            alert.informativeText = "请先选择要处理的照片"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        // 只处理选中的照片
        let photosToProcess = [selectedPhoto!]
        
        if photosToProcess.isEmpty {
            print("没有需要处理的照片")
            return
        }
        
        print("开始处理 \(photosToProcess.count) 张照片")
        
        Task {
            for photo in photosToProcess {
                do {
                    print("处理照片: \(photo.originalURL.lastPathComponent)")
                    
                    // 更新状态为处理中
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .processing
                            photos[index].progress = 0
                        }
                    }
                    
                    try await imageProcessor.processPhoto(
                        photo, 
                        with: appSettings.watermarkSettings,
                        outputDir: appSettings.outputDirectory,
                        progressHandler: { progress in
                            // 确保在主线程上更新 UI
                            Task { @MainActor in
                                if let index = self.photos.firstIndex(where: { $0.id == photo.id }) {
                                    // 使用临时变量来确保触发 UI 更新
                                    var updatedPhoto = self.photos[index]
                                    updatedPhoto.progress = progress
                                    self.photos[index] = updatedPhoto
                                    
                                    // 添加调试输出
                                    print("更新照片进度: \(photo.originalURL.lastPathComponent) - \(progress)")
                                }
                            }
                        }
                    )
                    
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .completed
                            photos[index].progress = 1.0
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
    
    func processAllPhotos() {
        print("processAllPhotos 被调用")
        
        let photosToProcess = photos.filter { $0.processingStatus != .completed }
        
        if photosToProcess.isEmpty {
            print("没有需要处理的照片")
            let alert = NSAlert()
            alert.messageText = "没有待处理照片"
            alert.informativeText = "所有照片已处理完成"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        print("开始处理 \(photosToProcess.count) 张照片")
        
        Task {
            for photo in photosToProcess {
                do {
                    print("处理照片: \(photo.originalURL.lastPathComponent)")
                    
                    // 更新状态为处理中
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .processing
                            photos[index].progress = 0
                        }
                    }
                    
                    try await imageProcessor.processPhoto(
                        photo, 
                        with: appSettings.watermarkSettings,
                        outputDir: appSettings.outputDirectory,
                        progressHandler: { progress in
                            // 确保在主线程上更新 UI
                            Task { @MainActor in
                                if let index = self.photos.firstIndex(where: { $0.id == photo.id }) {
                                    // 使用临时变量来确保触发 UI 更新
                                    var updatedPhoto = self.photos[index]
                                    updatedPhoto.progress = progress
                                    self.photos[index] = updatedPhoto
                                    
                                    // 添加调试输出
                                    print("更新照片进度: \(photo.originalURL.lastPathComponent) - \(progress)")
                                }
                            }
                        }
                    )
                    
                    await MainActor.run {
                        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                            photos[index].processingStatus = .completed
                            photos[index].progress = 1.0
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
    
    // 添加照片
    func addPhotos(from urls: [URL]) {
        print("🟢 addPhotos called with \(urls.count) URLs")
        urls.forEach { print("🟢 URL: \($0.path)") }
        
        let validUrls = urls.filter { isImageFile($0) }
        print("🟢 Valid image URLs: \(validUrls.count)")
        
        let newPhotos = validUrls.map { Photo(originalURL: $0) }
        print("🟢 Created \(newPhotos.count) photo objects")
        
        if newPhotos.isEmpty {
            print("🟢 ⚠️ No valid photos to add!")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let oldCount = self.photos.count
            self.photos.append(contentsOf: newPhotos)
            print("🟢 Photos array updated: \(oldCount) -> \(self.photos.count)")
            
            // 强制 UI 刷新
            self.objectWillChange.send()
        }
    }
    
    // 移除照片
    func removePhoto(_ photo: Photo) {
        photos.removeAll { $0.id == photo.id }
    }
    
    // 处理拖放
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { (data, error) in
                defer { group.leave() }
                
                if let url = data as? URL {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.addPhotos(from: urls)
        }
        
        return true
    }
    
    // 打开文件对话框
    func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic]
        
        panel.begin { response in
            if response == .OK {
                DispatchQueue.main.async {
                    self.addPhotos(from: panel.urls)
                }
            }
        }
    }
    
    // 处理照片
    func processPhotos(with settings: WatermarkSettings) {
        guard !photos.isEmpty, !isProcessing else { return }
        
        isProcessing = true
        progress = 0.0
        
        // 使用设置中的输出目录
        let outputDir = settings.outputDirectory
        
        // 确保输出目录存在
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        Task {
            do {
                // 处理每张照片
                for (index, photo) in photos.enumerated() {
                    try await imageProcessor.processPhoto(
                        photo,
                        with: settings,
                        outputDir: outputDir
                    ) { progressValue in
                        // 更新总体进度
                        let photoProgress = progressValue / Double(self.photos.count)
                        let overallProgress = Double(index) / Double(self.photos.count) + photoProgress
                        
                        Task { @MainActor in
                            self.progress = overallProgress
                        }
                    }
                }
                
                // 处理完成
                await MainActor.run {
                    self.isProcessing = false
                    self.progress = 1.0
                    
                    // 打开输出目录
                    NSWorkspace.shared.open(outputDir)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = ErrorMessage(message: error.localizedDescription)
                }
            }
        }
    }
    
    // 获取输出目录
    private func getOutputDirectory() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputDir = documentsDirectory.appendingPathComponent("MacPhotoWatermark_\(timestamp)")
        
        // 创建目录
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        return outputDir
    }
    
    // 检查是否为图片文件
    private func isImageFile(_ url: URL) -> Bool {
        let supportedExtensions = ["jpg", "jpeg", "png", "heic"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }
}

// 错误消息模型
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
} 