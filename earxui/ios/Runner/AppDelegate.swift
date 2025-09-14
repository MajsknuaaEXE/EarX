import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // 使启动到首帧过渡颜色一致，避免白屏闪烁
    if let w = self.window {
      w.backgroundColor = UIColor(red: 0.0588, green: 0.2980, blue: 0.3608, alpha: 1.0) // #0F4C5C
      w.rootViewController?.view.backgroundColor = w.backgroundColor
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
