import SwiftUI

struct Sidebar: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        List {
            Section(header: Text("工具")) {
                Button(action: {
                    viewModel.clearPhotoList()
                }) {
                    Label("清空列表", systemImage: "trash")
                }
                .disabled(viewModel.photos.isEmpty)
                
                Button(action: {
                    print("开始处理照片")
                    viewModel.processSelectedPhotos()
                }) {
                    Label("处理选中照片", systemImage: "photo.badge.checkmark")
                }
                .disabled(viewModel.photos.isEmpty)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 200, maxWidth: 300)
    }
} 