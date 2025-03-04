import SwiftUI

struct PhotoListView: View {
    let photos: [Photo]
    let onRemove: (Photo) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                ForEach(photos) { photo in
                    PhotoPreviewView(photo: photo, onRemove: {
                        onRemove(photo)
                    })
                }
            }
            .padding()
        }
    }
}

// 单独的照片行组件
struct PhotoRow: View {
    let photo: Photo
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: statusIcon(for: photo))
                    .foregroundColor(statusColor(for: photo))
                
                Text(photo.originalURL.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if let error = photo.error {
                    Button(action: {
                        // 显示错误详情
                    }) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.yellow)
                    }
                    .help(error)
                }
                
                if photo.processingStatus == .processing {
                    Text("\(Int(photo.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 如果正在处理，显示进度条
            if photo.processingStatus == .processing {
                ProgressView(value: photo.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 6)
                    .padding(.top, 4)
                    .animation(.easeInOut, value: photo.progress)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .cornerRadius(4)
    }
    
    private func statusIcon(for photo: Photo) -> String {
        switch photo.processingStatus {
        case .pending:
            return "circle"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        }
    }
    
    private func statusColor(for photo: Photo) -> Color {
        switch photo.processingStatus {
        case .pending:
            return .gray
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
} 