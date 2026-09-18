import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111911),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── LIGNE 1 : Championnat + Pays + Heure ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E2E1E)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🏴', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${match.championship}  ·  ${match.country}',
                      style: GoogleFonts.barlow(
                        color: const Color(0xFF8FAA8F),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('HH:mm').format(match.matchTime),
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF8FAA8F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── LIGNE 2 : Équipe 1 — ⚽ — Équipe 2 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Équipe 1
                Expanded(
                  child: Text(
                    match.team1,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 19,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // Icône centrale
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text('⚽', style: TextStyle(fontSize: 18)),
                ),

                // Équipe 2
                Expanded(
                  child: Text(
                    match.team2,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 19,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // ── LIGNE 3 : Option (badge) + Cote (badge) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                // Badge option — bleu foncé style référence
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2A0A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: const Color(0xFF00E664).withOpacity(0.4)),
                    ),
                    child: Text(
                      match.optionChosen,
                      style: GoogleFonts.barlow(
                        color: const Color(0xFFE8F5E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Badge cote — vert vif
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E664),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    match.odds.toStringAsFixed(2),
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFF080D08),
                      fontSize: 18,
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