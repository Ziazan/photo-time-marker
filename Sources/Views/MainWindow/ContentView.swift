import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showSettings = false
    @State private var watermarkSettings = WatermarkSettings.default
    
    var body: some View {
        VStack(spacing: 0) {
            // 主内容区域
            if viewModel.photos.isEmpty {
                EmptyStateView(
                    onDrop: { urls in
                        viewModel.addPhotos(from: urls)
                    },
                    onClick: {
                        viewModel.openFileDialog()
                    }
                )
            } else {
                PhotoListView(
                    photos: viewModel.photos, 
                    onRemove: viewModel.removePhoto,
                    onDrop: { urls in
                        viewModel.addPhotos(from: urls)
                    }
                )
            }
            
            // 进度条（如果正在处理）
            if viewModel.isProcessing {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            // 左侧工具栏项
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    viewModel.openFileDialog()
                }) {
                    Label("添加照片", systemImage: "photo.on.rectangle.angled")
                }
                .help("添加照片")
                
                Divider()
                
                Button(action: {
                    viewModel.processPhotos(with: watermarkSettings)
                }) {
                    Label("开始处理", systemImage: "play.fill")
                }
                .help("开始处理")
                .disabled(viewModel.photos.isEmpty || viewModel.isProcessing)
                
                Divider()
                
                Menu {
                    Button(action: {
                        NSWorkspace.shared.open(watermarkSettings.outputDirectory)
                    }) {
                        Label("打开输出文件夹", systemImage: "folder")
                    }
                    
                    if !viewModel.photos.isEmpty {
                        Button(action: {
                            viewModel.clearPhotoList()
                        }) {
                            Label("清空列表", systemImage: "trash")
                        }
                    }
                } label: {
                    Label("查看", systemImage: "eye")
                }
                .help("查看选项")
            }
            
            // 右侧工具栏项
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    showSettings = true
                }) {
                    Label("设置", systemImage: "gear")
                }
                .help("水印设置")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: $watermarkSettings, isPresented: $showSettings)
        }
        .alert(item: $viewModel.errorMessage) { error in
            Alert(
                title: Text("错误"),
                message: Text(error.message),
                dismissButton: .default(Text("确定"))
            )
        }
    }
} 