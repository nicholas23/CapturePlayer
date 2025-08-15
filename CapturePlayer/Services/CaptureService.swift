// Sources/USBCapturePlayer/Services/CaptureService.swift
// 匯入 AVFoundation 框架，並標記為 @preconcurrency，表示它可能不是完全線程安全的
@preconcurrency import AVFoundation
// 匯入 SwiftUI 框架
import SwiftUI

// 定義一個 CaptureService 類別，遵從 ObservableObject 協議，使其可以在 SwiftUI 視圖中被觀察
@MainActor
class CaptureService: ObservableObject {
    // 使用 @Published 屬性包裝器，當 previewLayer 改變時，會自動通知相關的 SwiftUI 視圖更新
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    // 使用 @Published 屬性包裝器，當 isRunning 改變時，會自動通知相關的 SwiftUI 視圖更新
    @Published var isRunning = false

    // 私有的 AVCaptureSession 實例，用來管理擷取過程
    private var captureSession: AVCaptureSession?
    // 私有的 AVCaptureAudioPreviewOutput 實例，用來預覽音訊
    private var audioPreviewOutput: AVCaptureAudioPreviewOutput?

    // 使用 @MainActor 標記，確保這個方法在主線程上執行
    func start(videoDevice: AVCaptureDevice, audioDevice: AVCaptureDevice?) async {
        // 建立一個新的 AVCaptureSession
        captureSession = AVCaptureSession()
        // 確保 captureSession 已經成功建立
        guard let session = captureSession else { return }

        // 開始設定 session
        session.beginConfiguration()
        
        // 設定 session 的解析度為 1080p
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }

        // 設定影像輸入
        do {
            // 嘗試設定影像裝置的格式為 1080p
            try configureDevice(videoDevice, for: .hd1920x1080)
            
            // 建立影像輸入
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            // 如果可以將影像輸入加入 session，就加入它
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
        } catch {
            // 如果設定影像輸入時發生錯誤，就印出錯誤訊息並返回
            print("Error setting up video input: \(error)")
            session.commitConfiguration()
            return
        }

        // 設定聲音輸入
        if let audioDevice = audioDevice {
            do {
                // 建立聲音輸入
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                // 如果可以將聲音輸入加入 session，就加入它
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    print("Successfully added audio input: \(audioDevice.localizedName)")
                }
            } catch {
                // 如果設定聲音輸入時發生錯誤，就印出錯誤訊息
                print("Error setting up audio input: \(error)")
            }
        }
        
        // 設定聲音輸出以供預覽
        audioPreviewOutput = AVCaptureAudioPreviewOutput()
        // 如果可以將聲音輸出加入 session，就加入它
        if let audioOutput = audioPreviewOutput, session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            audioOutput.volume = 1.0
            print("Audio preview output added and volume set to 1.0")
        }

        // 提交 session 的設定
        session.commitConfiguration()

        // 建立影像預覽層
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // 設定影像預覽層的縮放模式
        self.previewLayer?.videoGravity = .resizeAspect

        // 在背景線程開始執行 session
        Task.detached(priority: .userInitiated) {
            session.startRunning()
            await MainActor.run {
                self.isRunning = true
            }
        }
    }

    // 使用 @MainActor 標記，確保這個方法在主線程上執行
    func stop() {
        // 確保 session 存在並且正在執行
        guard let session = captureSession, session.isRunning else { return }
        // 停止 session
        session.stopRunning()
        // 更新 isRunning 狀態
        isRunning = false
        // 清除預覽層和 session
        previewLayer = nil
        captureSession = nil
        audioPreviewOutput = nil
    }
    
    // 私有的方法，用來設定裝置的格式
    private func configureDevice(_ device: AVCaptureDevice, for preset: AVCaptureSession.Preset) throws {
        // 鎖定裝置以進行設定
        try device.lockForConfiguration()
        // 使用 defer 確保在方法結束時解除鎖定
        defer { device.unlockForConfiguration() }
        
        // 目標的影像尺寸
        var targetDimensions: CMVideoDimensions
        
        // 根據 preset 設定目標尺寸
        switch preset {
        case .hd1920x1080:
            targetDimensions = CMVideoDimensions(width: 1920, height: 1080)
        default:
            // 如果需要，可以加入其他的 preset
            return
        }
        
        // 找到最符合目標尺寸的格式
        let bestFormat = device.formats.first { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == targetDimensions.width && dimensions.height == targetDimensions.height
        }
        
        // 如果找到了符合的格式，就設定它
        if let format = bestFormat {
            device.activeFormat = format
            print("Successfully set format to 1920x1080")
        } else {
            // 如果找不到，就印出訊息
            print("Could not find a 1920x1080 format for the device.")
        }
    }
}
