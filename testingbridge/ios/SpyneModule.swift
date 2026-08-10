//
//  SpyneModule.swift
//  testingbridge
//
//  React Native bridge for SpyneAutomobileSDK.
//  Exposes the native module as `NativeModules.Spyne` (same name as Android).
//

import Foundation
import SpyneAutomobile
import UIKit

/// React Native event emitter that launches SpyneAutomobileSDK and forwards
/// shoot lifecycle callbacks to JavaScript.
@objc(Spyne)
class SpyneModule: RCTEventEmitter, SpyneShootDelegate {

  // MARK: - Configuration

  /// Replace these values with credentials from your Spyne before shipping.
  private enum Config {
    static let apiKey = "<YOUR_API_KEY_HERE>"
    static let schemaVersion: UInt64 = 222
  }

  // MARK: - RCTEventEmitter

  override init() {
    super.init()
  }

  /// Required by React Native so the module is initialized on the main queue.
  override static func requiresMainQueueSetup() -> Bool {
    true
  }

  /// Event names emitted to JavaScript via `NativeEventEmitter`.
  override func supportedEvents() -> [String]! {
    [
      "onShootInitiated",
      "onShootCompleted",
      "onShootExit",
    ]
  }

  // MARK: - Public RN API

  /**
   Starts a Spyne vehicle shoot.

   Mirrors the Android `Spyne.start(...)` signature so one JS API works on both platforms.

   - Parameters:
     - userId: Spyne user / email identifier (required by the host app).
     - vin: Optional 17-character VIN.
     - stockNumber: Optional dealer stock number.
     - registrationNumber: Optional registration / plate number.
     - locale: UI locale code (for example `"en"`). Empty values default to `"en"`.

   At least one of `vin`, `stockNumber`, or `registrationNumber` should be provided
   by the host app (the sample JS layer validates this before calling).
   */
  @objc(start:vin:stockNumber:registrationNumber:locale:)
  func start(
    _ userId: String,
    vin: String,
    stockNumber: String,
    registrationNumber: String,
    locale: String
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      guard let sourceViewController = self.topViewController() else {
        NSLog("[SpyneModule] Unable to find a presenting view controller")
        return
      }

      // Unlock landscape, then present the SDK host controller.
      OrientationHelper.unlockForSpyne { [weak self] in
        guard let self = self else { return }

        SpyneAutomobileSDK.initialize(
          apiKey: Config.apiKey,
          schemaVersion: Config.schemaVersion
        )

        SpyneSDKPresenter.resolvePresenter(from: sourceViewController) { presenter in
          let userData = UserData(userId: userId)
          let shootData = ShootData(
            vin: vin.isEmpty ? nil : vin,
            stockNumber: stockNumber.isEmpty ? nil : stockNumber,
            registrationNumber: registrationNumber.isEmpty ? nil : registrationNumber
          )

          let spyneSDK = SpyneAutomobileSDK.Builder(
            viewController: presenter,
            delegate: self
          )
          .setUserData(userData)
          .setShootData(shootData)
          .setEnvironment(.production)
          .setAppMode(.online)
          .setLocale(locale.isEmpty ? "en" : locale)
          .build()

          spyneSDK.startShoot()
        }
      }
    }
  }


  // MARK: - SpyneShootDelegate

  /// Called when a shoot session is created / initiated inside the SDK.
  func shootDidInitiate(
    shootData: SpyneAutomobile.ShootData,
    dealerVinId: String,
    mediaId: String,
    status: String
  ) {
    sendEvent(
      withName: "onShootInitiated",
      body: [
        "shootData": serialize(shootData),
        "dealerVinId": dealerVinId,
        "mediaId": mediaId,
        "status": status,
      ]
    )
  }

  /// Called when the user finishes a shoot (including reshots).
  func shootDidComplete(
    shootData: SpyneAutomobile.ShootData,
    dealerVinId: String,
    mediaId: String,
    isReshoot: Bool
  ) {
    sendEvent(
      withName: "onShootCompleted",
      body: [
        "shootData": serialize(shootData),
        "dealerVinId": dealerVinId,
        "mediaId": mediaId,
        "isReshoot": isReshoot,
      ]
    )

    SpyneSDKPresenter.dismissIfNeeded {
      OrientationHelper.lockPortrait()
    }
  }

  /// Called when the user exits the shoot flow without completing it.
  func shootDidExit(
    shootData: SpyneAutomobile.ShootData,
    dealerVinId: String,
    mediaId: String
  ) {
    sendEvent(
      withName: "onShootExit",
      body: [
        "shootData": serialize(shootData),
        "dealerVinId": dealerVinId,
        "mediaId": mediaId,
      ]
    )

    SpyneSDKPresenter.dismissIfNeeded {
      OrientationHelper.lockPortrait()
    }
  }

  // MARK: - Private helpers

  /// Converts SDK shoot identity fields into a JS-friendly dictionary.
  private func serialize(_ shootData: SpyneAutomobile.ShootData) -> [String: Any] {
    [
      "vin": shootData.vin as Any,
      "stockNumber": shootData.stockNumber as Any,
      "registrationNumber": shootData.registrationNumber as Any,
    ]
  }

  /// Walks the presented view-controller hierarchy to find the top-most VC.
  private func topViewController(from root: UIViewController? = nil) -> UIViewController? {
    let rootVC = root ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .rootViewController

    if let presented = rootVC?.presentedViewController {
      return topViewController(from: presented)
    }
    if let nav = rootVC as? UINavigationController {
      return topViewController(from: nav.visibleViewController)
    }
    if let tab = rootVC as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    return rootVC
  }
}
