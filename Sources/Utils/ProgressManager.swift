import Foundation

class ProgressManager: ObservableObject {
    @Published var progress: Double = 0
    @Published var currentItemIndex: Int = 0
    @Published var totalItems: Int = 0
    @Published var isProcessing: Bool = false
    
    func start(totalItems: Int) {
        self.totalItems = totalItems
        self.currentItemIndex = 0
        self.progress = 0
        self.isProcessing = true
    }
    
    func advance() {
        currentItemIndex += 1
        progress = Double(currentItemIndex) / Double(totalItems)
        
        if currentItemIndex == totalItems {
            isProcessing = false
        }
    }
    
    func reset() {
        progress = 0
        currentItemIndex = 0
        totalItems = 0
        isProcessing = false
    }
} 