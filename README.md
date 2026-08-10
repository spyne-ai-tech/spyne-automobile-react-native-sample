# Spyne Automobile SDK — React Native Sample

A minimal React Native app that demonstrates how to integrate the **Spyne Automobile SDK** (guided vehicle photo shoot) on both **iOS** and **Android** through a custom native module.

The JavaScript layer collects vehicle identifiers (VIN / stock number / registration number), hands them to the native SDK, and listens for shoot lifecycle events coming back from native code.

---

## Contents

| Path | What it is |
| --- | --- |
| [testingbridge/](testingbridge) | The React Native app (RN 0.78.2, React 19, TypeScript) |
| [App.tsx](testingbridge/App.tsx) | Sample UI — form, validation, event listeners |
| [spyneBridge.js](testingbridge/spyneBridge.js) | Thin JS wrapper around `NativeModules.Spyne` |
| [android/app/src/main/java/com/testingbridge/](testingbridge/android/app/src/main/java/com/testingbridge) | Android native module (`SpyneModule.kt`, `SpynePackage.kt`) and SDK init in `MainApplication.kt` |
| [ios/SpyneModule.swift](testingbridge/ios/SpyneModule.swift) | iOS native module (`RCTEventEmitter` + `SpyneShootDelegate`) |
| [ios/SpyneSDKHelpers.swift](testingbridge/ios/SpyneSDKHelpers.swift) | AWS upload bootstrap, orientation locking, SDK presentation helpers |
| [ios/SpyneModule.m](testingbridge/ios/SpyneModule.m) | Objective-C exports for the Swift module |

The app id / bundle name is `testingbridge` (Android `applicationId com.testingbridge`).

---

## How the bridge works

Both platforms expose the same native module under the JS name **`Spyne`**, so one JS API works everywhere:

```js
import {start} from './spyneBridge';

start(userId, vin, stockNumber, registrationNumber, 'en');
```

`start` takes five strings: `userId` (required), `vin`, `stockNumber`, `registrationNumber` (at least one of the three required — a 17-character VIN when supplied), and a `locale` (defaults to `en`).

The native side emits three events, consumed in [App.tsx](testingbridge/App.tsx) via `NativeEventEmitter`:

| Event | Payload |
| --- | --- |
| `onShootInitiated` | `{shootData, dealerVinId, mediaId, status}` |
| `onShootCompleted` | `{shootData, dealerVinId, mediaId, isReshoot}` |
| `onShootExit` | `{shootData, dealerVinId, mediaId}` |

`shootData` is `{vin, stockNumber, registrationNumber}`. The sample only logs these events — a real host app would persist `dealerVinId` / `mediaId` or navigate on completion.

---

## Prerequisites

- Node.js **>= 18**
- A working [React Native environment](https://reactnative.dev/docs/environment-setup)
- **Android:** JDK 17, Android SDK 35, NDK 27.1.12297006 (Kotlin 1.9.24 / AGP 8.7.3, `minSdk 26`)
- **iOS:** Xcode with an iOS **16.0+** deployment target, Ruby >= 2.6.10 and CocoaPods ~> 1.12 (`bundle install` from `testingbridge/` uses the bundled [Gemfile](testingbridge/Gemfile))
- Spyne credentials: an **Enterprise API key**, and a **JitPack auth token** for the private Android SDK repo

---

## Configuration

The repo ships with placeholders. Replace all of them before running:

| Placeholder | File | Purpose |
| --- | --- | --- |
| `<YOUR_API_KEY_HERE>` | [MainApplication.kt](testingbridge/android/app/src/main/java/com/testingbridge/MainApplication.kt) | Android Spyne API key (`SpyneAutomobileSDK.init`) |
| `<YOUR_API_KEY_HERE>` | [SpyneModule.swift](testingbridge/ios/SpyneModule.swift) | iOS Spyne API key |
| `<YOUR_JITPACK_AUTH_TOKEN>` | [android/gradle.properties](testingbridge/android/gradle.properties) (`authToken`) | Credentials for the JitPack repo hosting the Android SDK |
| `<YOUR_IDENTITY_POOL_ID>` | [SpyneSDKHelpers.swift](testingbridge/ios/SpyneSDKHelpers.swift) and [ios/awsconfiguration.json](testingbridge/ios/awsconfiguration.json) | Cognito identity pool used for S3 uploads |
| `<YOUR_COGNITO_USER_POOL_ID>`, `<YOUR_COGNITO_APP_CLIENT_ID>`, `<YOUR_S3_BUCKET_NAME>` | [ios/awsconfiguration.json](testingbridge/ios/awsconfiguration.json) | Remaining AWS metadata for the upload path |

Android also expects a valid `android/app/google-services.json` (the Google Services plugin is applied).

---

## Running the app

All commands run from `testingbridge/`.

```bash
npm install
```

Start Metro in its own terminal:

```bash
npm start
```

### Android

```bash
npm run android
```

Pulls the SDK from JitPack — `authToken` in `android/gradle.properties` must be set or dependency resolution fails.

### iOS

Install pods first (CocoaPods covers React Native only; the Spyne SDK and AWS SDK come from Swift Package Manager):

```bash
cd ios && bundle install && bundle exec pod install
```

Then:

```bash
npm run ios
```

Open `ios/testingbridge.xcworkspace` (not the `.xcodeproj`) when building from Xcode.

### Tests and lint

```bash
npm test
```

```bash
npm run lint
```

