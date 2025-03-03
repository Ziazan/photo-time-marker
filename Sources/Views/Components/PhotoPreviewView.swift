import SwiftUI

struct PhotoPreviewView: View {
    let photo: Photo
    
    var body: some View {
        VStack {
            let url = photo.processedURL ?? photo.originalURL
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                if let processedURL = photo.processedURL {
                    Button("在访达中显示") {
                        NSWorkspace.shared.selectFile(processedURL.path, 
                                                   inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
} 