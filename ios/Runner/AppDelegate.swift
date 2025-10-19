import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key
    // For development/testing, using a placeholder key
    // In production, use --dart-define-from-file with env/prod.env.json
    GMSServices.provideAPIKey("AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
