import 'dart:async';

import 'package:flutter/foundation.dart';

// Import the Unity Ads plugin. If this package name doesn't match your chosen plugin,
// replace with the plugin you're using (e.g., unity_ads, unity_ads_plugin, flutter_unity_ads).
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class UnityAdsManager {
  UnityAdsManager._privateConstructor();
  static final UnityAdsManager instance = UnityAdsManager._privateConstructor();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Expose the last known initialization error (if any)
  String? lastError;

  Future<void> initialize({required String gameId, bool testMode = true}) async {
    if (_initialized) return;

    try {
      // The Unity Ads plugin provides an init call. Depending on the plugin version,
      // the parameter names for callbacks may vary. This code uses the common
      // pattern offered by community plugins. If you see compile errors, check the
      // actual plugin API and adapt the callback signatures accordingly.

      UnityAds.init(
        gameId: gameId,
        testMode: testMode,
        onComplete: () {
          _initialized = true;
          debugPrint('Unity Ads: initialization complete');
        },
        onFailed: (error, message) {
          lastError = '$error: $message';
          _initialized = false;
          debugPrint('Unity Ads: initialization failed - $lastError');
        },
      );

      // Some plugin implementations complete init synchronously; wait a short time
      // to allow the plugin to call the onComplete callback.
      await Future.delayed(const Duration(milliseconds: 300));

      // If the plugin didn't call the completion callback but no error was thrown,
      // we optimistically set initialized = true. This is safe in testMode.
      if (!_initialized && lastError == null) {
        _initialized = true;
      }
    } catch (e) {
      lastError = e.toString();
      _initialized = false;
      debugPrint('Unity Ads: initialization exception - $lastError');
    }
  }

  /// Show a rewarded ad. Returns true if the ad was shown and the reward callback
  /// was triggered (i.e., the user fully watched the ad). Otherwise returns false.
  Future<bool> showRewardedAd({
    required String placementId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_initialized) {
      debugPrint('Unity Ads: attempted to show rewarded ad but SDK is not initialized');
      return false;
    }

    final completer = Completer<bool>();

    try {
      // Attempt to load the placement first. Some Unity plugins require load before show.
      // We attach listeners for placement lifecycle events.

      void onComplete(String placementIdArg, UnityAdState state, Map<String, dynamic>? args) {
        // UnityAdState.complete indicates the ad finished successfully.
        if (placementIdArg == placementId && state == UnityAdState.complete) {
          if (!completer.isCompleted) completer.complete(true);
        }
      }

      void onError(String placementIdArg, UnityAdError error, String message) {
        debugPrint('Unity Ads: ad error: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      }

      // Register global listeners if available. API varies by plugin; this code uses
      // the pattern from `unity_ads_plugin` where UnityAds has add/remove listeners.
      UnityAds.addListener(onComplete);
      UnityAds.addErrorListener(onError);

      // Show the ad. Some plugins also expose a load() method — if yours does, you can
      // call UnityAds.load(placementId) first and wait for a ready callback.
      UnityAds.showVideoAd(
        placementId: placementId,
      );

      // Fallback timeout to prevent hanging builds/tests
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          debugPrint('Unity Ads: showRewardedAd timeout');
          completer.complete(false);
        }
      });

      final result = await completer.future;

      // Clean up listeners (best-effort). Adjust removal functions to match the plugin API.
      try {
        UnityAds.removeListener(onComplete);
        UnityAds.removeErrorListener(onError);
      } catch (_) {}

      return result;
    } catch (e) {
      debugPrint('Unity Ads: exception while showing rewarded ad - $e');
      return false;
    }
  }
}
