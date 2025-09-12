import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/level_provider.dart';
import '../../models/level_model.dart';

class LevelView extends ConsumerStatefulWidget {
  const LevelView({Key? key}) : super(key: key);

  @override
  ConsumerState<LevelView> createState() => _LevelViewState();
}

class _LevelViewState extends ConsumerState<LevelView> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('ログインが必要です')),
          );
        }
        return _buildLevelView(user.uid);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildLevelView(String userId) {
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final levelsAsync = ref.watch(levelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('レベル'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: userLevelAsync.when(
        data: (userLevel) {
          if (userLevel == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'レベル情報が見つかりません',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return levelsAsync.when(
            data: (levels) => _buildLevelContent(userLevel!, levels),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('エラー: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildLevelContent(UserLevelModel userLevel, List<LevelModel> levels) {
    final currentLevelInfo = levels.firstWhere(
      (level) => level.level == userLevel.currentLevel,
      orElse: () => LevelModel(
        level: userLevel.currentLevel,
        name: 'レベル ${userLevel.currentLevel}',
        requiredPoints: 0,
        description: '現在のレベル',
        iconUrl: '',
        rewards: [],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 現在のレベルカード
          _buildCurrentLevelCard(userLevel, currentLevelInfo),
          const SizedBox(height: 24),
          
          // レベル一覧
          const Text(
            'レベル一覧',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildLevelList(userLevel, levels),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelCard(UserLevelModel userLevel, LevelModel currentLevelInfo) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'レベル ${userLevel.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentLevelInfo.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${userLevel.totalPoints} ポイント',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 次のレベルへの進捗
            _buildProgressToNextLevel(userLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressToNextLevel(UserLevelModel userLevel) {
    final progress = userLevel.progressToNextLevel;
    final pointsToNext = userLevel.pointsToNextLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '次のレベルまで',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '$pointsToNext ポイント',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}% 完了',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelList(UserLevelModel userLevel, List<LevelModel> levels) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final isCurrentLevel = level.level == userLevel.currentLevel;
        final isUnlocked = level.level <= userLevel.currentLevel;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isCurrentLevel ? 4 : 2,
          color: isCurrentLevel ? Colors.blue.shade50 : null,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? (isCurrentLevel ? Colors.blue : Colors.green)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                isCurrentLevel
                    ? Icons.star
                    : isUnlocked
                        ? Icons.check_circle
                        : Icons.lock,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              'レベル ${level.level}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentLevel ? Colors.blue.shade700 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.name),
                const SizedBox(height: 4),
                Text(
                  '必要ポイント: ${level.requiredPoints}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (level.rewards.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '報酬: ${level.rewards.join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
            trailing: isCurrentLevel
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '現在',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : isUnlocked
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.lock, color: Colors.grey),
          ),
        );
      },
    );
  }
}
