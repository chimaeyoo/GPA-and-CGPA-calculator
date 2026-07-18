GPA & CGPA Calculator (Offline-first)

This project is an offline-first GPA and CGPA calculator tailored for Nigerian universities and polytechnics. All user data is stored locally on the user's device (Hive / SharedPreferences). No Supabase or Firebase is required for the core app functionality.

CI builds
- The codemagic.yaml workflow supports both signed builds (if you provide a base64 keystore via KEYSTORE_BASE64) and an unsigned fallback build for testing when no keystore is provided.

Unity Ads
- The app initializes Unity Ads in test mode by default so you can safely test rewarded video flows without affecting production analytics.
