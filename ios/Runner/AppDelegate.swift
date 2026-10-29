import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var ultimaEroareApns: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Captează eroarea nativă reală de înregistrare APNs - din Dart,
  // `getAPNSToken()` întoarce doar `null` indiferent dacă tokenul "încă nu
  // a sosit" sau dacă Apple a refuzat explicit înregistrarea, deci nu putem
  // deosebi cele două cazuri fără asta.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    AppDelegate.ultimaEroareApns = error.localizedDescription
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "evidenta_auto/diagnostic",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "ultimaEroareApns":
        result(AppDelegate.ultimaEroareApns)
      case "inregistreazaRemote":
        // Apel explicit, nu doar cel automat Firebase (swizzling) - pe
        // tiparul "implicit engine" al AppDelegate-ului, înregistrarea
        // automată nu pare să pornească deloc (nici succes, nici eșec).
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
