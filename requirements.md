---
title: Mac照片水印工具需求文档
version: 1.0.0
date: 2024-03-19
---

# Mac照片水印工具需求文档

## 1. 项目概述
开发一个 macOS 桌面应用，用于批量为照片添加时间水印。应用将读取照片的 EXIF 信息获取拍摄时间，在照片右下角添加时间水印，并将处理后的照片保存到新的文件夹中。

## 2. 系统要求

### 2.1 运行环境
- macOS 11.0 或更高版本
- 最小内存：8GB RAM
- 存储空间：根据处理图片数量动态调整

### 2.2 开发环境
- Xcode 14.0+
- Swift 5.0+
- SwiftUI
- Core Image 框架
- Photos 框架

## 3. 核心功能需求

### 3.1 用户界面
- **主窗口布局**
  - 拖拽区域：支持拖拽导入照片
  - 预览区域：显示已导入照片列表和预览
  - 设置面板：水印样式配置
  - 进度指示器：显示处理进度

- **设置选项**
  - 水印位置微调（右下角为默认位置）
  - 字体选择
  - 字体大小调整（默认值：照片短边的 2%）
  - 字体颜色选择（默认：白色）
  - 文字阴影/描边设置
  - 时间格式选择

### 3.2 核心功能
- **照片导入**
  - 支持拖拽导入
  - 支持菜单导入
  - 支持常见图片格式（JPG、PNG、HEIC）
  - 显示导入文件数量和总大小

- **EXIF 处理**
  - 读取照片拍摄时间
  - 处理不同时区的时间信息
  - 处理缺失 EXIF 信息的情况

- **水印处理**
  - 时间格式化显示
  - 水印位置计算
  - 保持原图质量
  - 保留原始 EXIF 信息

- **导出功能**
  - 自动创建输出文件夹
  - 保持原始文件名
  - 可选导出图片质量
  - 处理完成后可选打开输出文件夹

### 3.3 性能要求
- 支持批量处理（无限制张数）
- 使用多线程处理
- 内存使用优化
- 处理进度实时显示

## 4. 技术规范

### 4.1 项目结构
```
MacPhotoWatermark/
├── Sources/
│ ├── App/
│ │ └── MacPhotoWatermarkApp.swift
│ ├── Views/
│ │ ├── MainWindow/
│ │ ├── Settings/
│ │ └── Components/
│ ├── Models/
│ │ ├── Photo.swift
│ │ └── WatermarkSettings.swift
│ ├── Services/
│ │ ├── ImageProcessor.swift
│ │ ├── EXIFReader.swift
│ │ └── FileManager.swift
│ └── Utils/
│ ├── DateFormatter.swift
│ └── ImageUtils.swift
└── Resources/
└── Assets.xcassets
```


### 4.2 数据模型
```swift
struct Photo {
let id: UUID
let originalURL: URL
let creationDate: Date?
var processedURL: URL?
var processingStatus: ProcessingStatus
}
struct WatermarkSettings {
var position: CGPoint
var fontSize: CGFloat
var fontName: String
var textColor: NSColor
var shadowEnabled: Bool
var dateFormat: String
}
```

### 4.3 核心类职责

- **ImageProcessor**: 负责图片处理和水印添加
- **EXIFReader**: 负责读取和解析 EXIF 信息
- **FileManager**: 负责文件操作和目录管理
- **MainViewModel**: 负责业务逻辑和状态管理

## 5. 用户体验要求

### 5.1 交互设计
- 拖拽操作响应及时
- 处理过程可取消
- 错误提示友好
- 支持键盘快捷键

### 5.2 界面反馈
- 导入进度显示
- 处理进度显示
- 成功/失败状态显示
- 处理完成通知

## 6. 错误处理
- 文件格式不支持
- EXIF 信息缺失
- 存储空间不足
- 文件访问权限
- 处理失败恢复

## 7. 开发优先级
1. 基础界面框架
2. 照片导入功能
3. EXIF 读取功能
4. 水印添加功能
5. 批量处理功能
6. 设置界面
7. 性能优化
8. 用户体验改进

## 8. 测试要求
- 单元测试覆盖核心功能
- UI 测试覆盖主要流程
- 性能测试（大量图片处理）
- 内存泄漏测试
- 错误处理测试

## 9. 交付标准
- 代码注释完整
- 实现所有核心功能
- 通过所有测试用例
- 无内存泄漏
- 性能符合要求