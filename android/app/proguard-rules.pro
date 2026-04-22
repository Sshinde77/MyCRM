# Keep Flutter + plugin metadata required at runtime.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase Messaging classes used via reflection/service discovery.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Preserve annotations/signatures commonly needed by serialization/retrofit-style code.
-keepattributes Signature,*Annotation*,EnclosingMethod,InnerClasses
