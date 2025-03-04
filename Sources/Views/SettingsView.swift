import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var settings: WatermarkSettings
    @Binding var isPresented: Bool
    @State private var selectedColor: Color
    @State private var showDirectoryPicker = false
    
    // 添加数值格式化器
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = false
        formatter.minimum = 0
        formatter.maximum = 1000
        return formatter
    }()
    
    init(settings: Binding<WatermarkSettings>, isPresented: Binding<Bool>) {
        self._settings = settings
        self._isPresented = isPresented
        
        // 将 ColorComponents 转换为 Color
        let colorComponents = settings.wrappedValue.textColor
        self._selectedColor = State(initialValue: Color(
            red: colorComponents.redComponent,
            green: colorComponents.greenComponent,
            blue: colorComponents.blueComponent,
            opacity: colorComponents.alphaComponent
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("水印设置")
                .font(.title)
                .padding(.bottom, 10)
            
            Group {
                Text("日期格式:")
                TextField("日期格式", text: $settings.dateFormat)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("字体:")
                TextField("字体名称", text: $settings.fontName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("字体大小:")
                Slider(value: $settings.fontSize, in: 0.01...0.1, step: 0.005)
                    .frame(maxWidth: 300)
                Text("当前大小: \(Int(settings.fontSize * 1000))‰")
                
                Text("水印颜色:")
                ColorPicker("选择颜色", selection: $selectedColor)
                    .onChange(of: selectedColor) { oldValue, newValue in
                        if let cgColor = newValue.cgColor {
                            let ciColor = CIColor(cgColor: cgColor)
                            settings.textColor = ColorComponents(
                                redComponent: Double(ciColor.red),
                                greenComponent: Double(ciColor.green),
                                blueComponent: Double(ciColor.blue),
                                alphaComponent: Double(ciColor.alpha)
                            )
                        }
                    }
                
                Text("水印位置:")
                HStack {
                    Text("距右边距:")
                    TextField("", value: $settings.marginRight, formatter: numberFormatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("像素")
                    
                    Spacer()
                    
                    Text("距下边距:")
                    TextField("", value: $settings.marginBottom, formatter: numberFormatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("像素")
                }
                .padding(.vertical, 5)
                
                Text("输出文件夹:")
                HStack {
                    Text(settings.outputDirectory.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("选择...") {
                        showDirectoryPicker = true
                    }
                }
                .onAppear {
                    // 确保输出目录存在
                    try? FileManager.default.createDirectory(at: settings.outputDirectory, 
                                                          withIntermediateDirectories: true)
                }
            }
            
            HStack {
                Spacer()
                Button("取消") {
                    isPresented = false
                }
                Button("保存") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 450)
        .background {
            EmptyView().onChange(of: showDirectoryPicker) { oldValue, newValue in
                if newValue {
                    selectOutputDirectory()
                }
            }
        }
    }
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "选择输出文件夹"
        panel.message = "请选择处理后图片的保存位置"
        
        panel.begin { response in
            showDirectoryPicker = false
            
            if response == .OK, let url = panel.url {
                settings.outputDirectory = url
            }
        }
    }
} 