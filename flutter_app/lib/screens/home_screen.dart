import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';
import '../widgets/top_banner_ad.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/category_card.dart';
import '../widgets/splash_ad_dialog.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();

    // Précharger l'interstitiel AdMob
    SplashAdManager.preload();

    // Afficher splash pub après 1 seconde si 2h écoulées
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) SplashAdManager.showIfNeeded(context);
    });
  }

  Future<void> _load() async {
    final cats = await SupabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D08),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Bannière AdMob top (visible sur toutes les pages)
            const TopBannerAd(),

            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Text('⚽', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    'PRONOXPERT',
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFF00E664),
                      fontSize: 28,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pronostics du jour',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // ── Grille catégories + native ad
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : RefreshIndicator(
                      color: const Color(0xFF00E664),
                      backgroundColor: const Color(0xFF111911),
                      onRefresh: _load,
                      child: _buildContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // ── Grille 2 colonnes des 8 catégories
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => CategoryCard(
                category: _categories[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      category: _categories[index],
                    ),
                  ),
                ),
              ),
              childCount: _categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
          ),
        ),

        // ── Native Ad AdMob sous la grille des catégories
        // Instance indépendante #1 (home screen)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: NativeAdWidget(), // ← instance propre à home
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF111911),
      highlightColor: const Color(0xFF1E2E1E),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111911),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}