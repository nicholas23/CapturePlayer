// Sources/USBCapturePlayer/Services/DeviceDiscovery.swift
// 匯入 AVFoundation 框架，用於處理影音相關任務
import AVFoundation

// 定義一個 DeviceDiscovery 類別，遵從 ObservableObject 協議，使其可以在 SwiftUI 視圖中被觀察
class DeviceDiscovery: ObservableObject {
    // 使用 @Published 屬性包裝器，當 videoDevices 陣列改變時，會自動通知相關的 SwiftUI 視圖更新
    @Published var videoDevices: [AVCaptureDevice] = []
    // 使用 @Published 屬性包裝器，當 audioDevices 陣列改變時，會自動通知相關的 SwiftUI 視圖更新
    @Published var audioDevices: [AVCaptureDevice] = []

    // 初始化方法，在建立實例時會自動掃描裝置
    init() {
        scanForDevices()
    }

    // 掃描可用的影音裝置
    func scanForDevices() {
        // 判斷作業系統版本是否為 macOS 14.0 或以上
        if #available(macOS 14.0, *) {
            // 使用 AVCaptureDevice.DiscoverySession 尋找所有外接、內建廣角相機和麥克風的影像裝置
            videoDevices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.external, .builtInWideAngleCamera, .microphone],
                mediaType: .video,
                position: .unspecified
            ).devices

            // 使用 AVCaptureDevice.DiscoverySession 尋找所有外接、麥克風和內建麥克風的聲音裝置
            audioDevices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.external, .microphone, .builtInMicrophone],
                mediaType: .audio,
                position: .unspecified
            ).devices
        } else {
            // 對於舊版 macOS 的處理
            // 使用 AVCaptureDevice.DiscoverySession 尋找內建廣角相機的影像裝置
            videoDevices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            ).devices

            // 使用 AVCaptureDevice.DiscoverySession 尋找內建麥克風的聲音裝置
            audioDevices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInMicrophone],
                mediaType: .audio,
                position: .unspecified
            ).devices
        }
    }
}
