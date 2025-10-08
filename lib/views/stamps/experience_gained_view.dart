import 'package:flutter/material.dart';
import 'badge_awarded_view.dart';

class ExperienceGainedView extends StatelessWidget {
  final int gainedExperience;
  final int? newLevel; // null の場合はレベル表示を隠す
  final List<Map<String, dynamic>>? badges; // 渡された場合は確認で直接遷移

  const ExperienceGainedView({
    Key? key,
    required this.gainedExperience,
    this.newLevel,
    this.badges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFFFF6B35), size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      '経験値を獲得！',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$gainedExperience XP',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    if (newLevel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'レベル $newLevel',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final list = badges;
                    if (list != null && list.isNotEmpty) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => BadgeAwardedView(badges: list),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


