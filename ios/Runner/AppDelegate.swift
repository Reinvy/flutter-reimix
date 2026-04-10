import Flutter
import UIKit
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let controller = engineBridge.flutterViewController
    let channel = FlutterMethodChannel(
      name: "reimix/media_store",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard self != nil else { return }
      switch call.method {
      case "querySongs":
        self?.querySongs(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func querySongs(result: @escaping FlutterResult) {
    MPMediaLibrary.requestAuthorization { status in
      DispatchQueue.main.async {
        guard status == .authorized else {
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: "Apple Music / media library access was not granted.",
            details: nil
          ))
          return
        }

        let query = MPMediaQuery.songs()
        guard let items = query.items else {
          result([])
          return
        }

        let songs: [[String: Any?]] = items.compactMap { item in
          guard let assetURL = item.assetURL else { return nil }
          let durationMs = Int(item.playbackDuration * 1000)
          return [
            "filePath"  : assetURL.absoluteString,
            "title"     : item.title,
            "artist"    : item.artist,
            "album"     : item.albumTitle,
            "duration"  : durationMs,
            "track"     : item.albumTrackNumber > 0 ? item.albumTrackNumber : nil,
            "year"      : nil as Any?,   // MPMediaItem doesn't expose release year directly
            "mimeType"  : nil as Any?,
            "genre"     : item.genre,
          ]
        }
        result(songs)
      }
    }
  }
}
