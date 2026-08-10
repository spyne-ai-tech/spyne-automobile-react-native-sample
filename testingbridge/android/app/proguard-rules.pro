# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# react-native-config
#-keep class com.cars24.dealerapp.stage.BuildConfig { *; }
#-keep class com.cars24.dealerapp.BuildConfig { *; }
# react-native-svg
-keep public class com.horcrux.svg.** {*;}
-keep class com.spyneai.sdk.sdk.** {*;}




# Credit Vidya
-ignorewarnings
-keepattributes *Annotation*,EnclosingMethod,Signature
# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-optimizations !method/inlining/*

-keepclasseswithmembers class * {
  public void onPayment*(...);
}
# Notification Service
#-keepnames class com.cars24.dealerapp.notifications.** { *; }
# Models
#-keep class com.cars24.dealerapp.models.** { *; }
-keep public class com.dylanvann.fastimage.* {*;}
-keep public class com.dylanvann.fastimage.** {*;}
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

#glide

-keep public class * implements com.bumptech.glide.module.GlideModule

-keep class * extends com.bumptech.glide.module.AppGlideModule {

 <init>(...);

}

-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {

  **[] $VALUES;

  public *;

}

-keep class com.bumptech.glide.load.data.ParcelFileDescriptorRewinder$InternalRewinder {

  *** rewind();

}



# Picasso

-dontwarn com.squareup.okhttp.**





# removes such information by default, so configure it to keep all of it.

-keepattributes Signature



# For using GSON @Expose annotation

-keepattributes *Annotation*



# Gson specific classes

-dontwarn sun.misc.**



# Application classes that will be serialized/deserialized over Gson

-keep class com.google.gson.examples.android.model.** { <fields>; }



# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,

# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)

-keep class * extends com.google.gson.TypeAdapter

-keep class * implements com.google.gson.TypeAdapterFactory

-keep class * implements com.google.gson.JsonSerializer

-keep class * implements com.google.gson.JsonDeserializer



# Prevent R8 from leaving Data object members always null

-keepclassmembers,allowobfuscation class * {

  @com.google.gson.annotations.SerializedName <fields>;

}



# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.

-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken

-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken







#-keepclassmembernames class com.spyneai.shoot.data.model.CarsBackgroundRes { <fields>;