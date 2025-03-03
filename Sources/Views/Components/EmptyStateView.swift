import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("拖拽照片到这里")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("支持 JPG、PNG 和 HEIC 格式")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.textBackgroundColor).opacity(0.1))
    }
} 