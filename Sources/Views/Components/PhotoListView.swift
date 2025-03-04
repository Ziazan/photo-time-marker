import SwiftUI
import UniformTypeIdentifiers

struct PhotoListView: View {
    let photos: [Photo]
    let onRemove: (Photo) -> Void
    var onDrop: ([URL]) -> Void
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    @State private var isTargeted = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(photos) { photo in
                    PhotoPreviewView(photo: photo, onRemove: {
                        onRemove(photo)
                    })
                }
                
                // 添加一个拖放区域作为"添加更多"按钮
                VStack {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                    
                    Text("添加更多照片")
                        .font(.caption)
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                }
                .frame(width: 150, height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                )
                .contentShape(Rectangle())
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: .some($isTargeted)) { providers in
                    handleDrop(providers: providers)
                }
            }
            .padding()
        }
        .background(Color(.textBackgroundColor).opacity(0.05))
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        print("🟣 PhotoListView: Drop detected with \(providers.count) providers")
        
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            group.enter()
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { (data, error) in
                defer { group.leave() }
                
                if let url = data as? URL {
                    urls.append(url)
                } else if let data = data as? Data {
                    if let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    } else if let urlString = String(data: data, encoding: .utf8),
                              let url = URL(string: urlString) {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                onDrop(urls)
            }
        }
        
        return true
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