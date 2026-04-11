import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';

class ResultScreen extends StatelessWidget {
  final Plant? plant;
  final double confidence;
  final String imagePath;

  const ResultScreen({
    super.key,
    required this.plant,
    required this.confidence,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Low confidence or plant not found
    if (confidence < 0.50 || plant == null) {
      return _buildUnknownScreen(context);
    }

    final bool isToxic = plant!.category.toUpperCase() == 'TOXIC';

    if (isToxic) {
      return _buildToxicScreen(context);
    }

    return _buildEdibleScreen(context);
  }

  // ─── Unknown / Low confidence ───────────────────────────────────────────────

  Widget _buildUnknownScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2e1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2e1a),
        iconTheme: const IconThemeData(color: Color(0xFFf0ede6)),
        title: const Text(
          'Result',
          style: TextStyle(color: Color(0xFFf0ede6)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, size: 80, color: Color(0xFFe8a020)),
            const SizedBox(height: 24),
            const Text(
              'Cannot identify safely',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf0ede6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (plant != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d4a2d),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Best guess: ${plant!.commonName}  (${(confidence * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(color: Color(0xFFa8d5a2), fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFc0392b).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFc0392b)),
              ),
              child: const Text(
                'DO NOT EAT\n\nConfidence too low to make a safe recommendation. Never eat a plant you cannot positively identify.',
                style: TextStyle(
                  color: Color(0xFFf0ede6),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Match: ${(confidence * 100).toStringAsFixed(0)}%  (Minimum 50% required)',
              style: const TextStyle(color: Color(0xFF6a8a6a), fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2d4a2d),
                foregroundColor: const Color(0xFFa8d5a2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOXIC screen ───────────────────────────────────────────────────────────

  Widget _buildToxicScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDanger: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant!.commonName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a2e1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant!.scientificName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TOXIC badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFc0392b).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFc0392b), width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dangerous, color: Color(0xFFc0392b), size: 32),
                        SizedBox(width: 12),
                        Text(
                          'TOXIC — Do Not Eat',
                          style: TextStyle(
                            color: Color(0xFFc0392b),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info cards
                  Row(
                    children: [
                      _infoCard('PREP NEEDED', 'None — Toxic', Icons.no_food),
                      const SizedBox(width: 8),
                      _infoCard('TOXICITY', plant!.dangerLevel, Icons.science),
                      const SizedBox(width: 8),
                      _infoCard('SEASON', plant!.season, Icons.calendar_today),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Why toxic
                  if (plant!.whyToxic.isNotEmpty) ...[
                    const Text(
                      'WHY TOXIC',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFc0392b),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plant!.whyToxic,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Symptoms
                  if (plant!.symptoms.isNotEmpty) ...[
                    const Text(
                      'SYMPTOMS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a2e1a),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...plant!.symptoms.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 8, color: Color(0xFFc0392b)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(s, style: const TextStyle(fontSize: 15, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Emergency
                  if (plant!.emergency.isNotEmpty) ...[
                    const Text(
                      'EMERGENCY ACTION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFc0392b),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFc0392b).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFc0392b).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        plant!.emergency,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _warningBanner(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIBLE screen ──────────────────────────────────────────────────────────

  Widget _buildEdibleScreen(BuildContext context) {
    final bool mustCook = !plant!.eatRaw && plant!.eatCooked;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDanger: false),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant!.commonName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a2e1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant!.scientificName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // EDIBLE badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27ae60).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF27ae60), width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF27ae60), size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Edible',
                          style: TextStyle(
                            color: Color(0xFF27ae60),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Must cook warning
                  if (mustCook) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe8a020).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFe8a020).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Color(0xFFe8a020)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Must be cooked first — do not eat raw',
                              style: TextStyle(
                                color: Color(0xFFe8a020),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Info cards
                  Row(
                    children: [
                      _infoCard(
                        'PREP NEEDED',
                        plant!.eatRaw ? 'Raw / Cooked' : 'Cook Only',
                        Icons.restaurant,
                      ),
                      const SizedBox(width: 8),
                      _infoCard('TOXICITY', plant!.dangerLevel, Icons.science),
                      const SizedBox(width: 8),
                      _infoCard('SEASON', plant!.season, Icons.calendar_today),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // HOW TO CONSUME
                  if (plant!.preparation.isNotEmpty) ...[
                    const Text(
                      'HOW TO CONSUME',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a2e1a),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...plant!.preparation.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF1a2e1a),
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Color(0xFFa8d5a2),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _warningBanner(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context, {required bool isDanger}) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF1a2e1a),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background: dark green when no image, image when available
            Container(color: const Color(0xFF1a2e1a)),
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const ColoredBox(color: Color(0xFF2d4a2d)),
            ),
            // Gradient overlay bottom
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                  colors: [Colors.transparent, Colors.white],
                ),
              ),
            ),
            // Confidence badge top right
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDanger
                      ? const Color(0xFFc0392b)
                      : const Color(0xFF27ae60),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(confidence * 100).toStringAsFixed(0)}% match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFf8f8f8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe0e0e0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1a2e1a), size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1a2e1a),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningBanner() {
    final warnings = plant?.warnings ?? [];
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe8a020).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe8a020).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFe8a020), size: 20),
              SizedBox(width: 8),
              Text(
                'WARNINGS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFe8a020),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $w',
                style: const TextStyle(
                  color: Color(0xFF7a5a00),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
