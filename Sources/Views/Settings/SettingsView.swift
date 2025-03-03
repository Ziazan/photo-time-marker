import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var isShowingDirectoryPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Form {
                Section(header: Text("输出设置")) {
                    HStack {
                        Text("输出文件夹:")
                        Spacer()
                        Text(settings.outputDirectory.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button("选择...") {
                            isShowingDirectoryPicker = true
                        }
                    }
                }
                
                Section(header: Text("水印设置")) {
                    HStack {
                        Text("日期格式:")
                        TextField("日期格式", text: Binding(
                            get: { settings.watermarkSettings.dateFormat },
                            set: { 
                                var newSettings = settings.watermarkSettings
                                newSettings.dateFormat = $0
                                settings.watermarkSettings = newSettings
                            }
                        ))
                    }
                    
                    ColorPicker("文字颜色:", selection: Binding(
                        get: { Color(settings.watermarkSettings.textColor) },
                        set: { 
                            var newSettings = settings.watermarkSettings
                            newSettings.textColor = NSColor($0)
                            settings.watermarkSettings = newSettings
                        }
                    ))
                    
                    HStack {
                        Text("字体大小:")
                        Slider(value: Binding(
                            get: { settings.watermarkSettings.fontSize * 100 },
                            set: { 
                                var newSettings = settings.watermarkSettings
                                newSettings.fontSize = $0 / 100
                                settings.watermarkSettings = newSettings
                            }
                        ), in: 1...10, step: 0.5)
                        Text("\(Int(settings.watermarkSettings.fontSize * 100))%")
                    }
                }
            }
            .padding()
        }
        .frame(width: 500, height: 300)
        .fileImporter(
            isPresented: $isShowingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                
                // 尝试获取目录访问权限
                guard selectedURL.startAccessingSecurityScopedResource() else {
                    print("无法访问所选目录")
                    return
                }
                
                // 直接使用用户选择的目录，不再创建子目录
                settings.outputDirectory = selectedURL
                
                selectedURL.stopAccessingSecurityScopedResource()
            case .failure(let error):
                print("选择目录失败: \(error)")
            }
        }
    }
} 