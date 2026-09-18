import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/match_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ════════════════════════════════════════
  // CATEGORIES
  // ════════════════════════════════════════

  /// Récupère toutes les catégories triées par order_index
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _client
          .from('categories')
          .select()
          .order('order_index', ascending: true);

      return (res as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getCategories : $e');
      return [];
    }
  }

  /// Récupère une catégorie par son slug
  static Future<CategoryModel?> getCategoryBySlug(String slug) async {
    try {
      final res = await _client
          .from('categories')
          .select()
          .eq('slug', slug)
          .single();

      return CategoryModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ getCategoryBySlug : $e');
      return null;
    }
  }

  // ════════════════════════════════════════
  // MATCHES — PRONOSTICS DU JOUR
  // ════════════════════════════════════════

  /// Récupère les matchs visibles et en attente de résultat
  /// pour une catégorie donnée, triés par heure de match
  static Future<List<MatchModel>> getMatchesByCategory(
      String categoryId) async {
    try {
      final res = await _client
          .from('matches')
          .select()
          .eq('category_id', categoryId)
          .eq('is_visible', true)
          .eq('result', 'pending')
          .order('match_time', ascending: true);

      return (res as List)
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getMatchesByCategory : $e');
      return [];
    }
  }

  /// Récupère tous les matchs d'une catégorie
  /// (visibles + masqués, tous résultats)
  /// Utilisé uniquement côté admin
  static Future<List<MatchModel>> getAllMatchesByCategory(
      String categoryId) async {
    try {
      final res = await _client
          .from('matches')
          .select()
          .eq('category_id', categoryId)
          .order('match_time', ascending: true);

      return (res as List)
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getAllMatchesByCategory : $e');
      return [];
    }
  }

  // ════════════════════════════════════════
  // HISTORIQUE — JOURS DISPONIBLES
  // ════════════════════════════════════════

  /// Retourne la liste des jours distincts (3 derniers mois)
  /// qui ont au moins un match avec résultat won ou lost
  /// Triés du plus récent au plus ancien
  static Future<List<DateTime>> getAvailableDays(String categoryId) async {
    try {
      final threeMonthsAgo =
          DateTime.now().subtract(const Duration(days: 90));
      final dateStr = _formatDate(threeMonthsAgo);

      final res = await _client
          .from('matches')
          .select('result_date')
          .eq('category_id', categoryId)
          .inFilter('result', ['won', 'lost'])
          .gte('result_date', dateStr)
          .not('result_date', 'is', null)
          .order('result_date', ascending: false);

      // Dédupliquer les dates
      final Set<String> seen = {};
      final List<DateTime> days = [];

      for (final row in (res as List)) {
        final d = row['result_date'] as String?;
        if (d != null && seen.add(d)) {
          days.add(DateTime.parse(d));
        }
      }

      return days;
    } catch (e) {
      debugPrint('❌ getAvailableDays : $e');
      return [];
    }
  }

  // ════════════════════════════════════════
  // HISTORIQUE — MATCHS PAR JOUR
  // ════════════════════════════════════════

  /// Retourne tous les matchs won/lost
  /// d'une catégorie pour un jour donné
  /// Triés par heure de match
  static Future<List<MatchModel>> getHistoryByDay({
    required String categoryId,
    required DateTime day,
  }) async {
    try {
      final dateStr = _formatDate(day);

      final res = await _client
          .from('matches')
          .select()
          .eq('category_id', categoryId)
          .eq('result_date', dateStr)
          .inFilter('result', ['won', 'lost'])
          .order('match_time', ascending: true);

      return (res as List)
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getHistoryByDay : $e');
      return [];
    }
  }

  // ════════════════════════════════════════
  // STATS HISTORIQUE
  // ════════════════════════════════════════

  /// Retourne les stats globales d'une catégorie
  /// sur les 3 derniers mois
  /// { total, won, lost, winRate }
  static Future<Map<String, dynamic>> getHistoryStats(
      String categoryId) async {
    try {
      final threeMonthsAgo =
          DateTime.now().subtract(const Duration(days: 90));
      final dateStr = _formatDate(threeMonthsAgo);

      final res = await _client
          .from('matches')
          .select('result')
          .eq('category_id', categoryId)
          .inFilter('result', ['won', 'lost'])
          .gte('result_date', dateStr);

      final list = res as List;
      final total = list.length;
      final won = list.where((m) => m['result'] == 'won').length;
      final lost = list.where((m) => m['result'] == 'lost').length;
      final winRate = total > 0
          ? double.parse(
              (won / total * 100).toStringAsFixed(1))
          : 0.0;

      return {
        'total':   total,
        'won':     won,
        'lost':    lost,
        'winRate': winRate,
      };
    } catch (e) {
      debugPrint('❌ getHistoryStats : $e');
      return {
        'total':   0,
        'won':     0,
        'lost':    0,
        'winRate': 0.0,
      };
    }
  }

  // ════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════

  /// Formate une DateTime en 'YYYY-MM-DD'
  /// Ex: DateTime(2026, 2, 23) → '2026-02-23'
  static String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}