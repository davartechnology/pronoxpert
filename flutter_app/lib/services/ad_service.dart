import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  // ════════════════════════════════════════
  // CONFIGURATION ADMOB
  // ════════════════════════════════════════

  // ⚠️ Remplacez ces IDs par vos vrais IDs AdMob
  // après validation de votre compte.
  // En mode debug, les IDs test Google sont utilisés
  // automatiquement et fonctionnent sans compte AdMob.

  // ── Android IDs ─────────────────────────
  static const String _androidBannerId =
      'ca-app-pub-2569412702560232/5097296153';
  static const String _androidInterstitialId =
      'ca-app-pub-2569412702560232/8733288837';
  static const String _androidNativeId =
      'ca-app-pub-2569412702560232/7559807962';
  static const String _androidSquareId =
      'ca-app-pub-2569412702560232/9060591895';

  // ── iOS IDs ─────────────────────────────
  static const String _iosBannerId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _iosInterstitialId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _iosNativeId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _iosSquareId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // ── IDs Test Google (debug uniquement) ──
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testNativeId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testSquareId =
      'ca-app-pub-3940256099942544/6300978111';

  // ════════════════════════════════════════
  // GETTERS IDs (debug vs production)
  // ════════════════════════════════════════

  static String get bannerAdUnitId {
    if (kDebugMode) return _testBannerId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosBannerId
        : _androidBannerId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosInterstitialId
        : _androidInterstitialId;
  }

  static String get nativeAdUnitId {
    if (kDebugMode) return _testNativeId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosNativeId
        : _androidNativeId;
  }

  static String get squareAdUnitId {
    if (kDebugMode) return _testSquareId;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosSquareId
        : _androidSquareId;
  }

  // ════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════

  /// À appeler une seule fois dans main()
  /// avant runApp()
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('✅ AdMob initialisé');
  }

  // ════════════════════════════════════════
  // SPLASH AD — INTERSTITIEL (toutes les 2h)
  // ════════════════════════════════════════

  static const String _splashKey     = 'last_splash_time';
  static const int    _splashInterval = 2 * 60 * 60 * 1000; // 2h en ms

  static InterstitialAd? _interstitialAd;
  static bool _interstitialLoaded = false;
  static bool _interstitialShowing = false;

  /// Précharger l'interstitiel au lancement de l'app
  /// Appeler dans initState() de HomeScreen
  static void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd    = ad;
          _interstitialLoaded = true;
          debugPrint('✅ Interstitiel chargé');
        },
        onAdFailedToLoad: (error) {
          _interstitialLoaded = false;
          _interstitialAd     = null;
          debugPrint('❌ Interstitiel échec : ${error.message}');
        },
      ),
    );
  }

  /// Vérifie si 2h se sont écoulées depuis
  /// la dernière affichage du splash
  static Future<bool> _shouldShowSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final last  = prefs.getInt(_splashKey) ?? 0;
    final now   = DateTime.now().millisecondsSinceEpoch;
    return (now - last) >= _splashInterval;
  }

  /// Enregistre l'heure actuelle comme
  /// dernier affichage du splash
  static Future<void> _markSplashShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _splashKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Affiche l'interstitiel si :
  /// - 2h se sont écoulées
  /// - L'interstitiel est chargé
  /// - Aucun interstitiel n'est déjà affiché
  static Future<void> showSplashIfNeeded() async {
    final should = await _shouldShowSplash();

    if (!should) {
      debugPrint('⏳ Interstitiel : pas encore 2h');
      return;
    }

    if (!_interstitialLoaded || _interstitialAd == null) {
      debugPrint('⏳ Interstitiel : pas encore chargé');
      // Tenter de recharger pour la prochaine fois
      preloadInterstitial();
      return;
    }

    if (_interstitialShowing) {
      debugPrint('⏳ Interstitiel : déjà affiché');
      return;
    }

    await _markSplashShown();
    _interstitialShowing = true;

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        debugPrint('✅ Interstitiel affiché');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd     = null;
        _interstitialLoaded  = false;
        _interstitialShowing = false;
        debugPrint('✅ Interstitiel fermé');
        // Précharger le prochain
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd     = null;
        _interstitialLoaded  = false;
        _interstitialShowing = false;
        debugPrint('❌ Interstitiel échec affichage : ${error.message}');
      },
    );

    await _interstitialAd!.show();
  }

  // ════════════════════════════════════════
  // BANNER AD — Chargement
  // ════════════════════════════════════════

  /// Crée et charge une bannière AdMob standard (320x50)
  /// À utiliser dans TopBannerAd widget
  static BannerAd createBannerAd({
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: listener,
    );
  }

  // ════════════════════════════════════════
  // NATIVE AD — Chargement
  // ════════════════════════════════════════

  /// Crée et charge une native ad avec template small
  /// Couleurs adaptées au thème vert/noir de l'app
  /// À utiliser dans NativeAdWidget
  static NativeAd createNativeAd({
    required NativeAdListener listener,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      listener: listener,
      request:  const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType:    TemplateType.small,
        mainBackgroundColor: const Color(0xFF111911),
        cornerRadius:    12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor:       const Color(0xFF080D08),
          backgroundColor: const Color(0xFF00E664),
          style:           NativeTemplateFontStyle.bold,
          size:            13,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFE8F5E8),
          style:     NativeTemplateFontStyle.bold,
          size:      14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF8FAA8F),
          style:     NativeTemplateFontStyle.normal,
          size:      12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF4D634D),
          style:     NativeTemplateFontStyle.normal,
          size:      11,
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // SQUARE AD — Medium Rectangle (300x250)
  // ════════════════════════════════════════

  /// Crée et charge une bannière carrée 300x250
  /// Utilisée uniquement dans la page Single
  static BannerAd createSquareAd({
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: squareAdUnitId,
      size:     AdSize.mediumRectangle,
      request:  const AdRequest(),
      listener: listener,
    );
  }

  // ════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════

  /// Réinitialise le timer du splash (pour tests)
  /// À ne jamais appeler en production
  static Future<void> resetSplashTimer() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_splashKey);
    debugPrint('🔄 Timer splash réinitialisé');
  }

  /// Retourne le temps restant avant le prochain splash
  /// Utile pour le debug
  static Future<Duration> timeUntilNextSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final last  = prefs.getInt(_splashKey) ?? 0;
    final now   = DateTime.now().millisecondsSinceEpoch;
    final diff  = _splashInterval - (now - last);
    if (diff <= 0) return Duration.zero;
    return Duration(milliseconds: diff);
  }
}