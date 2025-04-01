import Flutter
import UIKit
import Firebase
import OneSignalFramework

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Configure OneSignal
    // Replace with your actual OneSignal App ID from main.dart
    OneSignal.initialize("4d56fe0b-b1a7-4f4b-b6d6-6d5c4829f746")
    
    // Fix for the log level error - using proper enum value
    OneSignal.Debug.setLogLevel(.verbose)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
