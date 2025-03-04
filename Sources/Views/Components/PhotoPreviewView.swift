import SwiftUI

struct PhotoPreviewView: View {
    let photo: Photo
    var onRemove: (() -> Void)?
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: NSImage(contentsOf: photo.originalURL) ?? NSImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .clipped()
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(4)
                }
            }
            
            Text(photo.originalURL.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 140)
        }
        .padding(5)
        .background(Color(.textBackgroundColor).opacity(0.05))
        .cornerRadius(10)
    }
} 