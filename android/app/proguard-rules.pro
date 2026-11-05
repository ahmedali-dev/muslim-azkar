# Scheduled notifications survive release shrinking and reboot restoration.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature,InnerClasses,EnclosingMethod
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
