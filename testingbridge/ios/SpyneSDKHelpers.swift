//
//  SpyneSDKHelpers.swift
//  testingbridge
//
//  Supporting utilities for the SpyneAutomobileSDK React Native sample:
//  AWS upload bootstrap, orientation locking, and SDK presentation.
//

import AWSCore
import AWSMobileClientXCF
import AWSS3
import UIKit

// MARK: - AWSBootstrap

/// Configures AWS Cognito credentials and S3 Transfer Utility used by Spyne uploads.
///
/// Call once at app launch (see `AppDelegate`). Requires `awsconfiguration.json`
/// in the app bundle for Amplify / Cognito metadata.
@objc final class AWSBootstrap: NSObject {

  /// Sets the default AWS service configuration and registers `transferUtilityKey`.
  @objc static func configure() {
    if AWSServiceManager.default().defaultServiceConfiguration == nil {
      let credentialsProvider = AWSCognitoCredentialsProvider(
        regionType: .USEast1,
        identityPoolId: "<YOUR_IDENTITY_POOL_ID>"
      )
      let configuration = AWSServiceConfiguration(
        region: .USEast1,
        credentialsProvider: credentialsProvider
      )
      AWSServiceManager.default().defaultServiceConfiguration = configuration
    }

    AWSMobileClient.default().initialize { userState, error in
      if let error = error {
        NSLog("[AWSBootstrap] AWSMobileClient initialize error: %@", error.localizedDescription)
      } else {
        NSLog("[AWSBootstrap] AWSMobileClient ready. userState=%@", String(describing: userState))
      }
    }

    guard let serviceConfiguration = AWSServiceManager.default().defaultServiceConfiguration else {
      NSLog("[AWSBootstrap] defaultServiceConfiguration is nil after setup")
      return
    }

    let transferUtilityConfiguration = AWSS3TransferUtilityConfiguration()
    transferUtilityConfiguration.isAccelerateModeEnabled = true

    AWSS3TransferUtility.register(
      with: serviceConfiguration,
      transferUtilityConfiguration: transferUtilityConfiguration,
      forKey: "transferUtilityKey"
    ) { error in
      if let error = error {
        NSLog("[AWSBootstrap] Transfer Utility registration failed: %@", error.localizedDescription)
      } else {
        NSLog("[AWSBootstrap] Transfer Utility registered (transferUtilityKey)")
      }
    }
  }
}

// MARK: - OrientationHelper

/// Controls supported interface orientations while the Spyne shoot UI is active.
///
/// Spyne capture runs in landscape. Host apps should return
/// `OrientationHelper.supportedOrientations()` from
/// `application(_:supportedInterfaceOrientationsFor:)`.
@objc final class OrientationHelper: NSObject {
  private static var currentMask: UIInterfaceOrientationMask = .portrait

  /// Temporarily allows landscape and waits until the device / scene is landscape.
  @objc static func unlockForSpyne(completion: (() -> Void)? = nil) {
    updateSupportedOrientations(.landscape) {
      waitForOrientation(.landscape, completion: completion)
    }
  }

  /// Restricts the app back to portrait after the shoot UI is dismissed.
  @objc static func lockPortrait(completion: (() -> Void)? = nil) {
    updateSupportedOrientations(.portrait) {
      waitForOrientation(.portrait, completion: completion)
    }
  }

  /// Current orientation mask consulted by `AppDelegate`.
  @objc static func supportedOrientations() -> UIInterfaceOrientationMask {
    currentMask
  }

  private static func updateSupportedOrientations(
    _ mask: UIInterfaceOrientationMask,
    completion: (() -> Void)? = nil
  ) {
    DispatchQueue.main.async {
      currentMask = mask

      guard let windowScene = activeWindowScene() else {
        completion?()
        return
      }

      if #available(iOS 16.0, *) {
        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        windowScene.requestGeometryUpdate(preferences) { error in
          NSLog("[OrientationHelper] %@", error.localizedDescription)
        }

        windowScene.windows.forEach { window in
          window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
      }

      UIViewController.attemptRotationToDeviceOrientation()
      completion?()
    }
  }

  private static func waitForOrientation(
    _ target: UIInterfaceOrientationMask,
    completion: (() -> Void)?
  ) {
    let deadline = Date().addingTimeInterval(0.8)

    func poll() {
      if let scene = activeWindowScene() {
        let isMatch: Bool
        if target == .portrait {
          isMatch = scene.interfaceOrientation == .portrait
            || scene.interfaceOrientation == .portraitUpsideDown
        } else {
          isMatch = isLandscape(scene.interfaceOrientation)
        }

        if isMatch {
          completion?()
          return
        }

        if #available(iOS 16.0, *) {
          let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: target)
          scene.requestGeometryUpdate(preferences) { _ in }
          scene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        }
      }

      if Date() >= deadline {
        completion?()
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: poll)
    }

    poll()
  }

  private static func isLandscape(_ orientation: UIInterfaceOrientation) -> Bool {
    orientation == .landscapeLeft || orientation == .landscapeRight
  }

  private static func activeWindowScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
  }
}

// MARK: - SpyneSDKPresenter

/// Ensures SpyneAutomobileSDK is presented from a navigation context.
///
/// React Native root view controllers are often not inside a `UINavigationController`.
/// When needed, this helper presents a temporary fullscreen navigation host for the SDK.
@objc final class SpyneSDKPresenter: NSObject {
  private static weak var presentedNavigationController: UINavigationController?

  /**
   Resolves a view controller suitable for presenting SpyneAutomobileSDK.

   - Parameters:
     - sourceViewController: The current top view controller from the RN hierarchy.
     - completion: Called with a presenter that already has a navigation controller.
   */
  static func resolvePresenter(
    from sourceViewController: UIViewController,
    completion: @escaping (UIViewController) -> Void
  ) {
    if sourceViewController.navigationController != nil {
      completion(sourceViewController)
      return
    }

    if let navigationController = presentedNavigationController,
       let hostViewController = navigationController.viewControllers.first {
      completion(hostViewController)
      return
    }

    let hostViewController = UIViewController()
    hostViewController.view.backgroundColor = .black

    let navigationController = UINavigationController(rootViewController: hostViewController)
    navigationController.modalPresentationStyle = .fullScreen
    navigationController.modalTransitionStyle = .crossDissolve
    navigationController.isNavigationBarHidden = true
    presentedNavigationController = navigationController

    sourceViewController.present(navigationController, animated: true) {
      completion(hostViewController)
    }
  }

  /// Dismisses the temporary presenter if one was created by `resolvePresenter`.
  static func dismissIfNeeded(completion: (() -> Void)? = nil) {
    guard let navigationController = presentedNavigationController else {
      completion?()
      return
    }

    navigationController.dismiss(animated: true) {
      presentedNavigationController = nil
      completion?()
    }
  }
}
