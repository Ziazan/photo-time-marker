import SwiftUI

struct PhotoListView: View {
    var photos: [Photo]
    @Binding var selectedPhoto: Photo?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(photos) { photo in
                    PhotoRow(photo: photo, isSelected: selectedPhoto?.id == photo.id)
                        .contentShape(Rectangle())
                        .background(selectedPhoto?.id == photo.id ? Color.accentColor.opacity(0.2) : Color.clear)
                        .onTapGesture {
                            // 确保选择逻辑正确
                            if selectedPhoto?.id == photo.id {
                                selectedPhoto = nil  // 再次点击取消选择
                            } else {
                                selectedPhoto = photo  // 选择新照片
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

// 单独的照片行组件
struct PhotoRow: View {
    let photo: Photo
    let isSelected: Bool
    
    var body: some View {
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