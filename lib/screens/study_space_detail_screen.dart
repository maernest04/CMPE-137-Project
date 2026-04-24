import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/widgets/review_modal_content.dart';
import 'package:cmpe_137_study_space/widgets/space_reviews_section.dart';

/// Passed via [GoRouter] `extra` when opening [StudySpaceDetailScreen].
class StudySpaceDetailArgs {
  final StudySpace space;
  final Future<void> Function()? onReviewSubmitted;

  const StudySpaceDetailArgs({
    required this.space,
    this.onReviewSubmitted,
  });
}

class StudySpaceDetailScreen extends StatelessWidget {
  final StudySpace space;
  final Future<void> Function()? onReviewSubmitted;

  const StudySpaceDetailScreen({
    super.key,
    required this.space,
    this.onReviewSubmitted,
  });

  void _showLeaveReviewModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ReviewModalContent(
          space: space,
          onReviewSubmitted: onReviewSubmitted,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasCoords = space.latitude != 0.0 || space.longitude != 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          space.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: space.imageUrl != null
                  ? Image.network(
                      space.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          space.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sjsuBlue,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.sjsuGold,
                            size: 28,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            space.rating.toStringAsFixed(1),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          space.building,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'At a glance',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailTag(
                        icon: Icons.volume_up,
                        label: space.noiseLevel,
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade900,
                      ),
                      if (space.hasOutlets)
                        _DetailTag(
                          icon: Icons.electrical_services,
                          label: 'Power outlets',
                          color: Colors.green.shade100,
                          textColor: Colors.green.shade900,
                        )
                      else
                        _DetailTag(
                          icon: Icons.power_off,
                          label: 'No outlets listed',
                          color: Colors.orange.shade50,
                          textColor: Colors.orange.shade900,
                        ),
                    ],
                  ),
                  if (space.description != null &&
                      space.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'About this space',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      space.description!.trim(),
                      style: textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Location',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: hasCoords
                          ? SelectableText(
                              '${space.latitude.toStringAsFixed(5)}, '
                              '${space.longitude.toStringAsFixed(5)}',
                              style: textTheme.bodyLarge,
                            )
                          : Text(
                              'Map coordinates are not available for this '
                              'space yet.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reviews',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SpaceReviewsSection(
                    space: space,
                    onReviewsMutated: onReviewSubmitted,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLeaveReviewModal(context),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Leave a review'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _DetailTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
