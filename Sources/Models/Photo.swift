import Foundation

struct Photo: Identifiable {
    let id = UUID()
    let originalURL: URL
    var processedURL: URL?
    var processingStatus: ProcessingStatus = .pending
    var progress: Double = 0.0
    var error: String?
    
    enum ProcessingStatus {
        case pending
        case processing
        case completed
        case failed
    }
} 