import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    var onDrop: ([URL]) -> Void
    var onClick: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            
            Text("将照片拖放到这里")
                .font(.title2)
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            
            Text("或点击此处选择照片")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("支持 JPG、PNG 和 HEIC 格式")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.textBackgroundColor).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            onClick()
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: .some($isTargeted)) { providers in
            print("🔴 Drop detected with \(providers.count) providers")
            
            let group = DispatchGroup()
            var urls: [URL] = []
            
            for (index, provider) in providers.enumerated() {
                group.enter()
                print("🔴 Processing provider \(index)")
                
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { (data, error) in
                    defer { 
                        print("🔴 Provider \(index) processing completed")
                        group.leave() 
                    }
                    
                    if let error = error {
                        print("🔴 Error loading item: \(error)")
                        return
                    }
                    
                    if let url = data as? URL {
                        print("🔴 Got URL directly: \(url.path)")
                        urls.append(url)
                    } else if let data = data as? Data {
                        // 尝试从数据创建URL
                        print("🔴 Got Data, trying to convert to URL")
                        if let urlString = String(data: data, encoding: .utf8),
                           let url = URL(string: urlString) {
                            print("🔴 Created URL from string: \(url.path)")
                            urls.append(url)
                        } else if let url = URL(dataRepresentation: data, relativeTo: nil) {
                            // 尝试直接从数据创建URL
                            print("🔴 Created URL from data: \(url.path)")
                            urls.append(url)
                        } else {
                            print("🔴 Could not create URL from data")
                        }
                    } else if let data = data {
                        print("🔴 Got data of unknown type: \(type(of: data))")
                    } else {
                        print("🔴 No data received")
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("🔴 All providers processed. Found \(urls.count) URLs")
                if !urls.isEmpty {
                    onDrop(urls)
                }
            }
            
            return true
        }
    }
} 