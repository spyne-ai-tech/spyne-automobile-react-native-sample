package com.testingbridge

import android.app.Activity
import android.content.Context
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.spyneai.sdk.start.SpyneAutomobileSDK
import com.spyneai.sdk.start.model.ShootData
import com.spyneai.sdk.start.model.UserData

@ReactModule(name = SpyneModule.NAME)
class SpyneModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext),
    SpyneAutomobileSDK.SpyneShootListener {

    companion object {
        const val NAME = "SpyneModule"
    }

    override fun getName(): String {
        return "Spyne"
    }

    @ReactMethod
    fun start(userId: String, vin: String, stockNumber: String, registrationNumber: String, locale: String) {
        val activity = currentActivity
        activity?.let {
            start(it, userId, vin, stockNumber, registrationNumber, locale)
        }
    }

    private fun start(context: Context, userId: String, vin: String, stockNumber: String, registrationNumber: String, locale: String) {
        val activity = currentActivity ?: return

        val userData = UserData(userId, null)
        val shootData = getShootData(vin, stockNumber, registrationNumber)

        try {
            val spyne = SpyneAutomobileSDK.Builder(context, this)
                .setUserData(userData)
                .setShootData(shootData)
                .setLocale(locale.takeIf { it.isNotEmpty() } ?: "en")
                .build()

            spyne.startShoot()
        } catch (e: Exception) {
            Log.e("SpyneModule", "Error starting SDK: ${e.message}", e)
            e.printStackTrace()
        }
    }

    private fun getShootData(vin: String?, stockNumber: String?, registrationNumber: String?): ShootData {
        val vinValue = vin?.takeIf { it.isNotEmpty() }
        val stockValue = stockNumber?.takeIf { it.isNotEmpty() }
        val regValue = registrationNumber?.takeIf { it.isNotEmpty() }

        // ShootData constructor order (from data class definition):
        // 1. vin: String?
        // 2. stockNumber: String?
        // 3. registrationNumber: String?
        // 4. templateId: String? (default null)
        return ShootData(vin = vinValue, stockNumber = stockValue, registrationNumber = regValue, templateId = null)
    }

    override fun onShootInitiated(shootData: ShootData, dealerVinId: String, mediaId: String, status: String) {
        // Log all callback data
        Log.d("SpyneModule", "onShootInitiated called")
        Log.d("SpyneModule", "ShootData - StockNumber: ${shootData.stockNumber}, RegistrationNumber: ${shootData.registrationNumber}, VIN: ${shootData.vin}")
        Log.d("SpyneModule", "DealerVinId: $dealerVinId")
        Log.d("SpyneModule", "MediaId: $mediaId")
        Log.d("SpyneModule", "Status: $status")

        // Send event to React Native
        val params = Arguments.createMap().apply {
            val shootDataMap = Arguments.createMap().apply {
                putString("stockNumber", shootData.stockNumber)
                putString("registrationNumber", shootData.registrationNumber)
                putString("vin", shootData.vin)
            }
            putMap("shootData", shootDataMap)
            putString("dealerVinId", dealerVinId)
            putString("mediaId", mediaId)
            putString("status", status)
        }

        sendEvent(reactApplicationContext, "onShootInitiated", params)
    }

    override fun onShootCompleted(shootData: ShootData, dealerVinId: String, mediaId: String, isReshoot: Boolean) {
        // Log all callback data
        Log.d("SpyneModule", "onShootCompleted called")
        Log.d("SpyneModule", "ShootData - StockNumber: ${shootData.stockNumber}, RegistrationNumber: ${shootData.registrationNumber}, VIN: ${shootData.vin}")
        Log.d("SpyneModule", "DealerVinId: $dealerVinId")
        Log.d("SpyneModule", "MediaId: $mediaId")
        Log.d("SpyneModule", "IsReshoot: $isReshoot")

        // Send event to React Native
        val params = Arguments.createMap().apply {
            val shootDataMap = Arguments.createMap().apply {
                putString("stockNumber", shootData.stockNumber)
                putString("registrationNumber", shootData.registrationNumber)
                putString("vin", shootData.vin)
            }
            putMap("shootData", shootDataMap)
            putString("dealerVinId", dealerVinId)
            putString("mediaId", mediaId)
            putBoolean("isReshoot", isReshoot)
        }

        sendEvent(reactApplicationContext, "onShootCompleted", params)
    }

    override fun onShootExit(shootData: ShootData, dealerVinId: String, mediaId: String) {
        // Log all callback data
        Log.d("SpyneModule", "onShootExit called")
        Log.d("SpyneModule", "ShootData - StockNumber: ${shootData.stockNumber}, RegistrationNumber: ${shootData.registrationNumber}, VIN: ${shootData.vin}")
        Log.d("SpyneModule", "DealerVinId: $dealerVinId")
        Log.d("SpyneModule", "MediaId: $mediaId")

        // Send event to React Native
        val params = Arguments.createMap().apply {
            val shootDataMap = Arguments.createMap().apply {
                putString("stockNumber", shootData.stockNumber)
                putString("registrationNumber", shootData.registrationNumber)
                putString("vin", shootData.vin)
            }
            putMap("shootData", shootDataMap)
            putString("dealerVinId", dealerVinId)
            putString("mediaId", mediaId)
        }

        sendEvent(reactApplicationContext, "onShootExit", params)
    }

    private fun sendEvent(reactContext: ReactContext, eventName: String, params: WritableMap?) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }
}
