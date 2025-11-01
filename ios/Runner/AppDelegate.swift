import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from Info.plist
    // SECURITY: API key is configured via --dart-define-from-file
    // The value is injected at build time via Xcode build phase script
    // See: env/dev.env.json (git-ignored) and docs/IOS_GOOGLE_MAPS_INTEGRATION.md
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      GMSServices.provideAPIKey(apiKey)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
