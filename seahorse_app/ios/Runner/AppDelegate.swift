import AVFoundation
import AudioToolbox
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let speechSynthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      registerCustomChannels(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerCustomChannels(messenger: FlutterBinaryMessenger) {
    let soundChannel = FlutterMethodChannel(
      name: "com.seahorse.app/scanner_sound",
      binaryMessenger: messenger
    )
    soundChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "playScanSuccessSound":
        AudioServicesPlaySystemSound(1057)
        result(true)
      case "playImportantNoticeSound", "playOrderAlertSound":
        AudioServicesPlaySystemSound(1007)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        result(true)
      case "speakText":
        guard let args = call.arguments as? [String: Any],
              let rawText = args["text"] as? String else {
          result(FlutterError(code: "EMPTY_TEXT", message: "Speech text is empty", details: nil))
          return
        }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
          result(FlutterError(code: "EMPTY_TEXT", message: "Speech text is empty", details: nil))
          return
        }
        self?.speakChineseText(text)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let dialerChannel = FlutterMethodChannel(
      name: "com.seahorse.app/phone_dialer",
      binaryMessenger: messenger
    )
    dialerChannel.setMethodCallHandler { call, result in
      guard call.method == "makePhoneCall" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let rawPhone = args["phoneNumber"] as? String else {
        result(FlutterError(code: "INVALID_NUMBER", message: "Phone number is empty", details: nil))
        return
      }
      let cleaned = rawPhone.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !cleaned.isEmpty,
            let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "tel://\(encoded)") else {
        result(FlutterError(code: "INVALID_NUMBER", message: "Invalid phone number", details: nil))
        return
      }
      DispatchQueue.main.async {
        if UIApplication.shared.canOpenURL(url) {
          UIApplication.shared.open(url, options: [:]) { opened in
            result(opened)
          }
        } else {
          result(false)
        }
      }
    }
  }

  private func speakChineseText(_ text: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      do {
        try AVAudioSession.sharedInstance().setCategory(
          .playback,
          mode: .spokenAudio,
          options: [.duckOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        // Ignore audio session error and attempt speech directly
      }

      if self.speechSynthesizer.isSpeaking {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
      }
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        ?? AVSpeechSynthesisVoice(language: "zh-Hans")
      utterance.rate = AVSpeechUtteranceDefaultSpeechRate
      utterance.pitchMultiplier = 1.05
      utterance.volume = 1.0
      self.speechSynthesizer.speak(utterance)
    }
  }
}
