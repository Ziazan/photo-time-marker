import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    var onDrop: ([URL]) -> Void
    var onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.secondary)
                
                Text("将照片拖放到这里")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("或点击此处选择照片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("支持 JPG、PNG 和 HEIC 格式")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.textBackgroundColor).opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
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
                onDrop(urls)
            }
            
            return true
        }
    }
} 