import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

class SplashAdManager {
  static const _splashKey = 'last_splash_time';
  static const _intervalMs = 2 * 60 * 60 * 1000; // 2h

  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  // Précharger l'interstitiel au lancement
  static void preload() {
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
        },
      ),
    );
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_splashKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if ((now - last) < _intervalMs) return;
    if (!_isLoaded || _interstitialAd == null) return;

    await prefs.setInt(_splashKey, now);

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isLoaded = false;
        // Précharger le prochain
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isLoaded = false;
      },
    );

    _interstitialAd!.show();
  }
}