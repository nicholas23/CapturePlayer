//
//  ContentView.swift
//  CapturePlayer
//
//  Created by Chaoshen Hsu on 2025/8/3.
//

// Sources/USBCapturePlayer/Views/ContentView.swift
// 匯入 SwiftUI 框架，用於建立使用者介面
import SwiftUI
// 匯入 AVFoundation 框架，用於處理影音相關任務
import AVFoundation

// 定義一個 ContentView 結構，遵從 View 協議，是應用程式的主要視圖
struct ContentView: View {
    // 使用 @StateObject 屬性包裝器，建立並持有一個 DeviceDiscovery 的實例
    // @StateObject 確保這個物件的生命週期與視圖的生命週期一致
    @StateObject private var deviceDiscovery = DeviceDiscovery()
    // 使用 @StateObject 屬性包裝器，建立並持有一個 CaptureService 的實例
    @StateObject private var captureService = CaptureService()
    
    @State private var selectedVideoDeviceID: String?
    @State private var selectedAudioDeviceID: String?

    // body 屬性是視圖的內容
    var body: some View {
        // 使用 VStack 垂直排列視圖
        VStack {
            HStack {
                Button("Update Devices") {
                    deviceDiscovery.scanForDevices()
                    updateDeviceSelection()
                }

                Picker("Video", selection: $selectedVideoDeviceID) {
                    ForEach(deviceDiscovery.videoDevices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(device.uniqueID as String?)
                    }
                }
                
                Picker("Audio", selection: $selectedAudioDeviceID) {
                    ForEach(deviceDiscovery.audioDevices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(device.uniqueID as String?)
                    }
                }
                
                Button(action: toggleCapture) {
                    Text(captureService.isRunning ? "Stop" : "Play")
                }
            }
            .padding()

            // 檢查 captureService.previewLayer 是否存在
            if let layer = captureService.previewLayer {
                // 如果存在，就顯示 VideoPreview 視圖
                VideoPreview(layer: layer)
                    .aspectRatio(1920/1080, contentMode: .fit)
                    .frame(maxWidth: 1920, maxHeight: 1080)

            } else {
                // 如果不存在，就顯示一個黑色的背景和提示文字
                ZStack {
                    Color.black
                    Text("Select a device and press Play")
                        .foregroundColor(.white)
                }
                .aspectRatio(1920/1080, contentMode: .fit)
                .frame(maxWidth: 1920, maxHeight: 1080)
            }
        }
        // 設定視圖的最小寬度和高度
        .frame(minWidth: 480, minHeight: 360 + 60)
        // 當視圖出現時，執行 setupCapture 方法
        .onAppear(perform: setupInitialDevices)
        // 當視圖消失時，執行 captureService.stop 方法
        .onDisappear(perform: captureService.stop)
    }

    private func setupInitialDevices() {
        deviceDiscovery.scanForDevices()
        updateDeviceSelection()
    }

    private func updateDeviceSelection() {
        if let usbVideoDevice = deviceDiscovery.videoDevices.first(where: { $0.localizedName.contains("USB") }) {
            selectedVideoDeviceID = usbVideoDevice.uniqueID
        } else {
            selectedVideoDeviceID = deviceDiscovery.videoDevices.first?.uniqueID
        }

        if let usbAudioDevice = deviceDiscovery.audioDevices.first(where: { $0.localizedName.contains("USB") }) {
            selectedAudioDeviceID = usbAudioDevice.uniqueID
        } else {
            selectedAudioDeviceID = deviceDiscovery.audioDevices.first?.uniqueID
        }
    }

    // 私有的方法，用來設定擷取
    private func toggleCapture() {
        if captureService.isRunning {
            captureService.stop()
        } else {
            guard let videoDeviceID = selectedVideoDeviceID,
                  let videoDevice = deviceDiscovery.videoDevices.first(where: { $0.uniqueID == videoDeviceID }) else {
                print("No video device selected")
                return
            }
            
            let audioDevice = deviceDiscovery.audioDevices.first(where: { $0.uniqueID == selectedAudioDeviceID })
            
            Task {
                await captureService.start(videoDevice: videoDevice, audioDevice: audioDevice)
            }
        }
    }
}

// 定義一個 VideoPreview 結構，遵從 NSViewRepresentable 協議，用來在 SwiftUI 中顯示 AppKit 的 NSView
struct VideoPreview: NSViewRepresentable {
    // 持有一個 AVCaptureVideoPreviewLayer 的實例
    let layer: AVCaptureVideoPreviewLayer

    // 建立並回傳一個 NSView
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // 允許視圖使用 layer
        view.wantsLayer = true
        // 將傳入的 layer 設定為視圖的 layer
        view.layer = layer
        // 設定 layer 的 frame 與視圖的 bounds 一致
        layer.frame = view.bounds
        // 設定 layer 的縮放模式
        layer.videoGravity = .resizeAspect
        return view
    }

    // 當 SwiftUI 視圖更新時，更新 NSView
    func updateNSView(_ nsView: NSView, context: Context) {
        // 確保 layer 的 frame 與視圖的 bounds 保持一致
        layer.frame = nsView.bounds
    }
}

// 定義一個預覽提供者，用來在 Xcode 的預覽畫布中顯示 ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
