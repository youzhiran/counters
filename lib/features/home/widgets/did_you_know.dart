part of '../home_page.dart';

Widget _buildDidYouKnowSection(BuildContext context) {
  final tips = _pickRandomTips(3);
  if (tips.isEmpty) return const SizedBox.shrink();

  const double cardWidth = 260;
  const double spacing = 12.0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader('你知道吗？', '掌握更多使用技巧'),
      const SizedBox(height: 12),
      SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: tips.length,
          separatorBuilder: (_, __) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final tip = tips[index];
            return SizedBox(
              width: cardWidth,
              child: _DidYouKnowCard(
                title: tip.title,
                description: tip.description,
              ),
            );
          },
        ),
      ),
    ],
  );
}

List<_DidYouKnowTip> _pickRandomTips(int count) {
  if (_kDidYouKnowTips.length <= count) {
    return List<_DidYouKnowTip>.from(_kDidYouKnowTips);
  }

  final indices = List<int>.generate(_kDidYouKnowTips.length, (i) => i);
  indices.shuffle(_didYouKnowRandom);
  return indices.take(count).map((i) => _kDidYouKnowTips[i]).toList();
}

class _DidYouKnowCard extends StatelessWidget {
  final String title;
  final String description;

  const _DidYouKnowCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
