import Flutter
import UIKit
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Bao dam iOS lay APNs token ngay khi khoi dong (khong hien popup xin quyen).
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // === Chuyen APNs token cho Firebase Auth (BAT BUOC cho Phone Auth iOS) ===
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    NSLog("APNS_DIAG: nhan duoc token (%d bytes) -> chuyen cho Firebase Auth", deviceToken.count)
    // Ban TestFlight/App Store => moi truong .prod (da xac nhan aps-environment=production).
    Auth.auth().setAPNSToken(deviceToken, type: .prod)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNS_DIAG: DANG KY THAT BAI -> %@", error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Cho Firebase Auth xu ly silent push khi xac minh so dien thoai.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      NSLog("APNS_DIAG: silent push -> Firebase Auth (phone verify)")
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}