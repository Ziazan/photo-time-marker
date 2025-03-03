import Foundation

struct Photo: Identifiable, Equatable, Hashable {
    let id = UUID()
    let originalURL: URL
    var processedURL: URL?
    var processingStatus: ProcessingStatus = .pending
    var error: String?
    var progress: Double = 0  // 添加进度属性，范围 0-1
    
    enum ProcessingStatus {
        case pending
        case processing
        case completed
        case failed
    }
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 实现 Hashable 协议
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 