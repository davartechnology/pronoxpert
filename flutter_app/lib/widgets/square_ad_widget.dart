import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SquareAdWidget extends StatefulWidget {
  const SquareAdWidget({super.key});

  @override
  State<SquareAdWidget> createState() => _SquareAdWidgetState();
}

class _SquareAdWidgetState extends State<SquareAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      // Format carré medium rectangle 300x250
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(14),
      width: 300,
      height: 250,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}