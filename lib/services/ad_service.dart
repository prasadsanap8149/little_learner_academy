import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Replace these with your actual AdMob IDs
  static const String _bannerAdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String _interstitialAdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String _rewardedAdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<BannerAd> createBannerAd() async {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  Future<void> loadInterstitialAd() async {
    if (await _firebaseService.isSubscribed()) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (await _firebaseService.isSubscribed()) return;

    if (_interstitialAd == null) {
      print('Interstitial ad not loaded');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
    _interstitialAd = null;
  }

  Future<void> loadRewardedAd() async {
    if (await _firebaseService.isSubscribed()) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> showRewardedAd(Function(int amount) onRewarded) async {
    if (await _firebaseService.isSubscribed()) return;

    if (_rewardedAd == null) {
      print('Rewarded ad not loaded');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(reward.amount.toInt()),
    );
    _rewardedAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
