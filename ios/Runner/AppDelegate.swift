import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Kept alive for the engine's lifetime.
  private var storageChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show Free Trial Shield alerts while
    // the app is in the foreground and route taps back to Dart.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Only runs when a scene creates the Flutter UI. Background App Intent
  // launches have no scene, so they never boot the engine.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.splitburn.app/storage",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getAppGroupPath":
        // nil (not an error) when the App Group entitlement is missing; Dart
        // turns that into AppGroupUnavailableException.
        result(
          FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedStorageConstants.appGroupIdentifier)?.path)
      case "reloadWidgets":
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStorageConstants.widgetKind)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    storageChannel = channel
  }
}
