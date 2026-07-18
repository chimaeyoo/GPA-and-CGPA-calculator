import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/unity_ads_manager.dart';

/// GpaViewModel: Responsible for initializing ad SDKs and exposing methods to show ads.
/// This is a lightweight view model suitable for integrating with Provider, Riverpod,
/// or any other state-management solution. For now it is self-contained and uses
/// the UnityAdsManager singleton.
class GpaViewModel extends ChangeNotifier {
  final UnityAdsManager _unity = UnityAdsManager.instance;

  bool _unityInitialized = false;
  bool get unityInitialized => _unityInitialized;

  // Expose the placement ids used by the app. These can be overridden via
  // constructor injection or runtime config if needed.
  final String unityGameId;
  final String rewardedPlacementId;
  final String interstitialPlacementId;
  final String bannerPlacementId;

  GpaViewModel({
    required this.unityGameId,
    this.rewardedPlacementId = 'Rewarded_Android',
    this.interstitialPlacementId = 'Interstitial_Android',
    this.bannerPlacementId = 'Banner_Android',
  });

  /// Initialize Unity Ads SDK. testMode is true by default for safe testing.
  Future<void> initializeUnityAds({bool testMode = true}) async {
    try {
      await _unity.initialize(gameId: unityGameId, testMode: testMode);
      _unityInitialized = _unity.isInitialized;
      notifyListeners();
      debugPrint('GpaViewModel: Unity Ads initialized? ${_unityInitialized}');
    } catch (e) {
      _unityInitialized = false;
      notifyListeners();
      debugPrint('GpaViewModel: Unity Ads initialization error: $e');
    }
  }

  /// Attempts to show a rewarded ad and calls the provided callback only when the
  /// reward condition (full watch) is met.
  Future<void> showRewardedAd({required VoidCallback onUserEarnedReward}) async {
    if (!_unity.isInitialized) {
      debugPrint('GpaViewModel: Unity SDK not initialized; will not attempt to show ad.');
      return;
    }

    final rewarded = await _unity.showRewardedAd(placementId: rewardedPlacementId);

    if (rewarded) {
      debugPrint('GpaViewModel: User earned reward from Unity rewarded ad.');
      try {
        onUserEarnedReward();
      } catch (e) {
        debugPrint('GpaViewModel: onUserEarnedReward callback threw: $e');
      }
    } else {
      debugPrint('GpaViewModel: Rewarded ad did not complete or failed to show.');
    }
  }
}
