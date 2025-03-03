import SwiftUI

struct PhotoPreviewView: View {
    @Binding var selectedPhoto: Photo?
    
    var body: some View {
        if let photo = selectedPhoto {
            AsyncImage(url: photo.originalURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                ProgressView()
            }
        } else {
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("未选择照片")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
} 