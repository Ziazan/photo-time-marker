import SwiftUI
import AppKit

struct PhotoPreviewView: View {
    let photo: Photo
    var onRemove: (() -> Void)?
    
    @State private var image: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if let image = loadImage() {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            ProgressView()
                        )
                }
                
                if isHovered {
                    Button(action: {
                        onRemove?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            
            Text(photo.originalURL.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 140)
        }
        .padding(8)
        .background(Color(.textBackgroundColor).opacity(0.05))
        .cornerRadius(10)
    }
    
    private func loadImage() -> NSImage? {
        if let image = image {
            return image
        }
        
        if let image = NSImage(contentsOf: photo.originalURL) {
            DispatchQueue.main.async {
                self.image = image
            }
            return image
        }
        
        return nil
    }
} 