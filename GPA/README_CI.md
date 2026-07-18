CI Signing Instructions

This file describes how to supply a keystore to Codemagic to produce a signed release APK.

1. Create a Java keystore locally (if you don't have one):

   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

2. Encode the keystore as base64 and add to Codemagic as an environment variable named KEYSTORE_BASE64:

   base64 key.jks | pbcopy   # macOS (or use base64 key.jks > key.jks.b64)

3. In Codemagic UI, create the following secure environment variables:
   - KEYSTORE_BASE64  (the base64 content of the key.jks)
   - KEYSTORE_PASSWORD
   - KEY_ALIAS
   - KEY_PASSWORD

4. Trigger the build in Codemagic. The workflow will decode the keystore and create android/key.properties before building.

Notes:
- Do NOT commit key.jks or key.properties into the repository.
- Also set any runtime secrets for Supabase (e.g., SUPABASE_URL, SUPABASE_ANON_KEY) and AdMob IDs as environment variables in Codemagic if required by your app.
