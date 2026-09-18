import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/match_model.dart';
import '../services/supabase_service.dart';
import '../widgets/top_banner_ad.dart';
import '../widgets/native_ad_widget.dart';

class HistoryScreen extends StatefulWidget {
  final CategoryModel category;
  const HistoryScreen({super.key, required this.category});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DateTime> _availableDays = [];
  List<MatchModel> _matches = [];
  bool _loadingDays = true;
  bool _loadingMatches = false;
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    final days = await SupabaseService.getAvailableDays(widget.category.id);
    if (mounted) {
      setState(() {
        _availableDays = days;
        _loadingDays = false;
      });
      if (days.isNotEmpty) _loadMatchesForDay(0);
    }
  }

  Future<void> _loadMatchesForDay(int index) async {
    setState(() => _loadingMatches = true);
    final matches = await SupabaseService.getHistoryByDay(
      categoryId: widget.category.id,
      day: _availableDays[index],
    );
    if (mounted) {
      setState(() {
        _matches = matches;
        _loadingMatches = false;
        _currentDayIndex = index;
      });
    }
  }

  // Stats du jour
  int get _wonCount => _matches.where((m) => m.result == 'won').length;
  int get _lostCount => _matches.where((m) => m.result == 'lost').length;
  double get _winRate => _matches.isEmpty ? 0 : (_wonCount / _matches.length * 100);

  DateTime? get _currentDay =>
      _availableDays.isNotEmpty ? _availableDays[_currentDayIndex] : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D08),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopBannerAd(),
            _buildHeader(),

            if (_loadingDays)
              const Expanded(child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E664)),
              ))
            else if (_availableDays.isEmpty)
              _buildNoHistory()
            else ...[
              _buildDateNav(),
              _buildDayStats(),
              Expanded(
                child: _loadingMatches
                    ? _buildShimmer()
                    : _matches.isEmpty
                        ? _buildEmptyDay()
                        : _buildMatchList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2E1E))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF111911),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2E1E)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Color(0xFF8FAA8F), size: 15),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    color: const Color(0xFFE8F5E8),
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'HISTORIQUE · 3 MOIS',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Nombre de jours disponibles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2A0A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E664).withOpacity(0.4)),
            ),
            child: Text(
              '${_availableDays.length} jours',
              style: GoogleFonts.barlow(
                color: const Color(0xFF00E664),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVIGATION DATE ──────────────────────────────────
  Widget _buildDateNav() {
    final day = _currentDay;
    final isFirst = _currentDayIndex == 0;
    final isLast = _currentDayIndex == _availableDays.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          // Bouton précédent (jour plus récent, index - 1)
          GestureDetector(
            onTap: isFirst ? null : () => _loadMatchesForDay(_currentDayIndex - 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFirst ? const Color(0xFF0A100A) : const Color(0xFF111911),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isFirst
                      ? const Color(0xFF111911)
                      : const Color(0xFF1E2E1E),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.chevron_left,
                      color: isFirst
                          ? const Color(0xFF2D3D2D)
                          : const Color(0xFFE8F5E8),
                      size: 18),
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

          // Date centrale
          Expanded(
            child: Column(
              children: [
                Text(
                  day != null
                      ? DateFormat('EEEE', 'fr_FR').format(day).toUpperCase()
                      : '',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day != null
                      ? DateFormat('dd MMMM yyyy', 'fr_FR').format(day)
                      : '',
                  style: GoogleFonts.bebasNeue(
                    color: const Color(0xFF00E664),
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_currentDayIndex + 1} / ${_availableDays.length}',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Bouton suivant (jour plus ancien, index + 1)
          GestureDetector(
            onTap: isLast ? null : () => _loadMatchesForDay(_currentDayIndex + 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isLast
                    ? const Color(0xFF0A100A)
                    : const Color(0xFF00E664),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
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
                  Icon(Icons.chevron_right,
                      color: isLast
                          ? const Color(0xFF2D3D2D)
                          : const Color(0xFF080D08),
                      size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS DU JOUR ────────────────────────────────────
  Widget _buildDayStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111911),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2E1E)),
      ),
      child: Row(
        children: [
          _statPill('MATCHS', '${_matches.length}', const Color(0xFF8FAA8F)),
          _divider(),
          _statPill('GAGNÉS', '$_wonCount', const Color(0xFF00E664)),
          _divider(),
          _statPill('PERDUS', '$_lostCount', const Color(0xFFFF4444)),
          _divider(),
          _statPill('TAUX', '${_winRate.toStringAsFixed(0)}%',
              _winRate >= 50 ? const Color(0xFF00E664) : const Color(0xFFFF6B00)),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.bebasNeue(color: color, fontSize: 22)),
          Text(label,
              style: GoogleFonts.barlow(
                  color: const Color(0xFF4D634D),
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 30,
        color: const Color(0xFF1E2E1E),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── LISTE MATCHS ─────────────────────────────────────
  Widget _buildMatchList() {
    final List<Widget> items = [];

    for (int i = 0; i < _matches.length; i++) {
      items.add(_HistoryMatchCard(match: _matches[i]));

      // Native ad toutes les 3 matchs
      if ((i + 1) % 3 == 0) {
        items.add(const NativeAdWidget());
      }
    }

    items.add(const SizedBox(height: 30));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ── ÉTATS VIDES ──────────────────────────────────────
  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text('Aucun résultat ce jour',
              style: GoogleFonts.barlow(
                  color: const Color(0xFF4D634D), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildNoHistory() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            Text('Aucun historique disponible',
                style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D), fontSize: 16)),
            const SizedBox(height: 8),
            Text('Les résultats apparaîtront ici',
                style: GoogleFonts.barlow(
                    color: const Color(0xFF2D3D2D), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF111911),
      highlightColor: const Color(0xFF1E2E1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 4,
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

// ══════════════════════════════════════════════════════
// WIDGET CARTE MATCH HISTORIQUE
// ══════════════════════════════════════════════════════
class _HistoryMatchCard extends StatelessWidget {
  final MatchModel match;
  const _HistoryMatchCard({required this.match});

  bool get _isWon => match.result == 'won';

  @override
  Widget build(BuildContext context) {
    final resultColor = _isWon
        ? const Color(0xFF00E664)
        : const Color(0xFFFF4444);
    final resultBg = _isWon
        ? const Color(0xFF0A2A0A)
        : const Color(0xFF2A0A0A);
    final resultIcon = _isWon ? '✅' : '❌';
    final resultLabel = _isWon ? 'GAGNÉ' : 'PERDU';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111911),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resultColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [

          // ── Ligne 1 : championnat + heure + badge résultat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E2E1E))),
            ),
            child: Row(
              children: [
                const Text('🏴', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${match.championship} · ${match.country}',
                    style: GoogleFonts.barlow(
                      color: const Color(0xFF8FAA8F),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Heure
                Text(
                  DateFormat('HH:mm').format(match.matchTime),
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF4D634D),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                // Badge résultat
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: resultBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: resultColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(resultIcon,
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        resultLabel,
                        style: GoogleFonts.barlow(
                          color: resultColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Ligne 2 : équipes
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('⚽',
                      style: const TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: Text(
                    match.team2,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // ── Ligne 3 : option + cote
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F0A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: const Color(0xFF1E2E1E)),
                    ),
                    child: Text(
                      match.optionChosen,
                      style: GoogleFonts.barlow(
                        color: const Color(0xFF8FAA8F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: resultBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: resultColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    match.odds.toStringAsFixed(2),
                    style: GoogleFonts.bebasNeue(
                      color: resultColor,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}