import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category_model.dart';
import '../models/match_model.dart';
import '../models/ad_model.dart';
import '../services/supabase_service.dart';
import '../widgets/top_banner_ad.dart';
import '../widgets/match_card.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/square_ad_widget.dart';
import 'history_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<MatchModel> _matches = [];
  List<AdModel> _nativeAds = [];
  bool _loading = true;
  bool _isSingle = false;

  // Pagination
  static const int _perPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _isSingle = widget.category.isSingle;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final matches = await SupabaseService.getMatchesByCategory(
        widget.category.id);
    if (mounted) {
      setState(() {
        _matches = matches;
        _loading = false;
        _currentPage = 0;
      });
    }
  }

  List<MatchModel> get _currentPageMatches {
    final start = _currentPage * _perPage;
    final end = (start + _perPage).clamp(0, _matches.length);
    if (start >= _matches.length) return [];
    return _matches.sublist(start, end);
  }

  int get _totalPages => (_matches.length / _perPage).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D08),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Bannière AdMob top
            const TopBannerAd(),

            // ── Header catégorie
            _buildHeader(),

            // ── Contenu
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : RefreshIndicator(
                      color: const Color(0xFF00E664),
                      backgroundColor: const Color(0xFF111911),
                      onRefresh: _load,
                      child: _matches.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
                    ),
            ),

            // ── Pagination (si plus d'une page)
            if (!_loading && _matches.isNotEmpty && _totalPages > 1)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E2E1E)),
        ),
      ),
      child: Row(
        children: [
          // Retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF111911),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2E1E)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF8FAA8F),
                size: 15,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Icône catégorie
          Text(
            widget.category.icon,
            style: const TextStyle(fontSize: 22),
          ),

          const SizedBox(width: 8),

          // Nom catégorie
          Expanded(
            child: Text(
              widget.category.name.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                color: const Color(0xFFE8F5E8),
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ),

          // Compteur matchs
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A0A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E664).withOpacity(0.4),
                ),
              ),
              child: Text(
                '${_matches.length} match${_matches.length > 1 ? 's' : ''}',
                style: GoogleFonts.barlow(
                  color: const Color(0xFF00E664),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // ── Bouton Historique ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(
                  category: widget.category,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111911),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2E1E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    color: Color(0xFF8FAA8F),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'HISTORIQUE',
                    style: GoogleFonts.barlow(
                      color: const Color(0xFF8FAA8F),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // LISTE MATCHS
  // ════════════════════════════════════════
  Widget _buildList() {
    final pageMatches = _currentPageMatches;
    final List<Widget> items = [];

    // Square ad en haut pour Single uniquement
    if (_isSingle) {
      items.add(const SquareAdWidget());
    }

    for (int i = 0; i < pageMatches.length; i++) {
      items.add(MatchCard(match: pageMatches[i]));

      // Native ad AdMob toutes les 3 matchs (sauf Single)
      if (!_isSingle && (i + 1) % 3 == 0) {
        items.add(const NativeAdWidget());
      }
    }

    items.add(const SizedBox(height: 16));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ════════════════════════════════════════
  // PAGINATION
  // ════════════════════════════════════════
  Widget _buildPagination() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage >= _totalPages - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF080D08),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2E1E)),
        ),
      ),
      child: Row(
        children: [
          // Précédent
          Expanded(
            child: GestureDetector(
              onTap: isFirst
                  ? null
                  : () {
                      setState(() => _currentPage--);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFF0A100A)
                      : const Color(0xFF111911),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isFirst
                        ? const Color(0xFF0A100A)
                        : const Color(0xFF1E2E1E),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      color: isFirst
                          ? const Color(0xFF2D3D2D)
                          : const Color(0xFFE8F5E8),
                      size: 20,
                    ),
                    Text(
                      'Précédent',
                      style: GoogleFonts.barlow(
                        color: isFirst
                            ? const Color(0xFF2D3D2D)
                            : const Color(0xFFE8F5E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Indicateur page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_currentPage + 1} / $_totalPages',
              style: GoogleFonts.barlow(
                color: const Color(0xFF4D634D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Suivant
          Expanded(
            child: GestureDetector(
              onTap: isLast
                  ? null
                  : () {
                      setState(() => _currentPage++);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isLast
                      ? const Color(0xFF0A2A0A)
                      : const Color(0xFF00E664),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant',
                      style: GoogleFonts.barlow(
                        color: isLast
                            ? const Color(0xFF2D3D2D)
                            : const Color(0xFF080D08),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isLast
                          ? const Color(0xFF2D3D2D)
                          : const Color(0xFF080D08),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // ÉTATS
  // ════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          Text(
            'Aucun pronostic disponible',
            style: GoogleFonts.barlow(
              color: const Color(0xFF4D634D),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard',
            style: GoogleFonts.barlow(
              color: const Color(0xFF2D3D2D),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF111911),
      highlightColor: const Color(0xFF1E2E1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111911),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}