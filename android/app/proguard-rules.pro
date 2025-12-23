-keepattributes Signature
-keepattributes *Annotation*

# flutter_local_notifications uses Gson TypeToken to persist scheduled notifications.
# R8/Proguard must keep generic signature metadata or Gson will throw:
# java.lang.RuntimeException: Missing type parameter.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

-keep class com.dexterous.flutterlocalnotifications.** { *; }
