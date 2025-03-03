import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            Sidebar(viewModel: viewModel)
            
            VStack {
                if viewModel.photos.isEmpty {
                    EmptyStateView()
                } else {
                    PhotoListView(photos: viewModel.photos, 
                                selectedPhoto: $viewModel.selectedPhoto)
                }
            }
            
            VStack {
                if viewModel.selectedPhoto == nil {
                    Text("请选择一张照片")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PhotoPreviewView(selectedPhoto: $viewModel.selectedPhoto)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 800, minHeight: 600)
        }
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