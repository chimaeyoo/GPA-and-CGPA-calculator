CI Signing & Unsigned Build Instructions

This file explains how Codemagic will behave for signing and unsigned fallback builds.

Signed build (recommended for Play Store release):
1. Generate a keystore locally if you don't have one:

   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

2. Base64-encode the keystore and add to Codemagic as a secure env var KEYSTORE_BASE64:

   base64 key.jks > key.jks.b64
   # copy contents of key.jks.b64 into Codemagic's KEYSTORE_BASE64 (secure)

3. In Codemagic app settings, add these secure environment variables:
   - KEYSTORE_BASE64
   - KEYSTORE_PASSWORD
   - KEY_ALIAS
   - KEY_PASSWORD

4. Trigger a build on branch ci/update-codemagic-unsigned-fallback (or ci/add-android-and-deps).

Unsigned build (convenient for quick testing without a keystore):
- If you do not set KEYSTORE_BASE64 (or related vars) in Codemagic, the workflow will skip keystore steps and still run the release build, producing an unsigned APK you can download and install for testing. You can sign it later locally if needed.

Local signing (if you have an unsigned APK and want to sign it locally):
- Align & sign the unsigned APK using apksigner (Android SDK build-tools):

  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore /path/to/key.jks app-release-unsigned.apk alias_name
  # or use apksigner (preferred):
  ${ANDROID_SDK_ROOT}/build-tools/<version>/apksigner sign --ks /path/to/key.jks --out app-release-signed.apk app-release-unsigned.apk

Notes:
- The repo intentionally does NOT contain any keystores or secret values.
- The app is offline-first and does not require Supabase/Firebase; local data is stored on-device.
