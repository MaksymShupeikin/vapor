import Flutter
import UIKit

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

    let shareChannel = FlutterMethodChannel(
      name: "vapor/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    shareChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareText" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let arguments = call.arguments as? [String: Any]
      let text = arguments?["text"] as? String ?? ""
      guard !text.isEmpty, let controller = self?.topViewController() else {
        result(nil)
        return
      }

      let activityController = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
      )
      if let popover = activityController.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(
          x: controller.view.bounds.midX,
          y: controller.view.bounds.midY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }

      controller.present(activityController, animated: true)
      result(nil)
    }
  }

  private func topViewController() -> UIViewController? {
    let windowScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { scene in
        scene.activationState == .foregroundActive
      }
    let keyWindow = windowScene?.windows.first { window in
      window.isKeyWindow
    }

    var topController = keyWindow?.rootViewController
    while let presentedController = topController?.presentedViewController {
      topController = presentedController
    }

    return topController
  }
}
