package com.testingbridge

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint
import com.facebook.react.defaults.DefaultReactHost
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.react.soloader.OpenSourceMergedSoMapping
import com.facebook.soloader.SoLoader
import com.spyneai.sdk.start.SpyneAutomobileSDK

class MainApplication : Application(), ReactApplication {
    // Replace with your Spyne Enterprise API key before running the app.
    private val SPYNE_API_KEY = "<YOUR_API_KEY_HERE>"

    override val reactNativeHost: ReactNativeHost = object : DefaultReactNativeHost(this as Application) {
        override fun getUseDeveloperSupport(): Boolean {
            return BuildConfig.DEBUG
        }

        override fun getPackages(): List<ReactPackage> {
            val packages = PackageList(this).packages.toMutableList()
            // Packages that cannot be autolinked yet can be added manually here, for example:
            // packages.add(MyReactNativePackage())
            packages.add(SpynePackage())
            return packages
        }

        override fun getJSMainModuleName(): String {
            return "index"
        }
    }

    override val reactHost: ReactHost
        get() = DefaultReactHost.getDefaultReactHost(applicationContext, reactNativeHost)

    override fun onCreate() {
        super.onCreate()
        try {
            SoLoader.init(this, OpenSourceMergedSoMapping)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Initialize SpyneAutomobileSDK with context and Enterprise API key
        SpyneAutomobileSDK.init(this, SPYNE_API_KEY)
    }
}
