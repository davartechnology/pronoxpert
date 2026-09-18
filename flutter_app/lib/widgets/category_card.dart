import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111911),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2E1E)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: const Color(0xFF00E664).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 12),
                  Text(
                    category.name.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFFE8F5E8),
                      fontSize: 17,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'VOIR LES PRONOS',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFF00E664),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Color(0xFF00E664), size: 13),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}