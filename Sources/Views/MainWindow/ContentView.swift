import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            Sidebar(viewModel: viewModel)
            
            VStack(spacing: 0) {
                Text("文件列表")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.textBackgroundColor).opacity(0.1))
                
                if viewModel.photos.isEmpty {
                    EmptyStateView()
                } else {
                    PhotoListView(photos: viewModel.photos, 
                                selectedPhoto: $viewModel.selectedPhoto)
                }
            }
            
            VStack {
                if let selectedPhoto = viewModel.selectedPhoto {
                    PhotoPreviewView(photo: selectedPhoto)
                } else {
                    Text("请选择一张照片")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
        .navigationTitle("照片打印")
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    viewModel.isShowingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(settings: viewModel.appSettings)
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
            viewModel.handleDroppedFiles(providers)
            return true
        }
    }
} 