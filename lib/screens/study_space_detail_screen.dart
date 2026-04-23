import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/widgets/review_modal_content.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/widgets/space_reviews_section.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';

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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Space?'),
        content: const Text('Are you sure you want to delete this study space? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await StudySpaceService.instance.deleteStudySpace(space.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study space deleted.')),
          );
          // If a callback was provided to refresh the parent list, call it.
          if (onReviewSubmitted != null) {
            await onReviewSubmitted!();
          }
          if (context.mounted) {
            context.pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete space: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAddress = space.address.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          space.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              AuthScope.of(context).savedSpaces.contains(space.id)
                  ? Icons.bookmark
                  : Icons.bookmark_outline,
            ),
            onPressed: () {
              final authService = AuthScope.of(context);
              if (!authService.isSignedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to save study spaces.')),
                );
                return;
              }
              authService.toggleSavedSpace(space.id);
            },
          ),
          if (AuthScope.of(context).uid == space.createdBy && space.createdBy.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(
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
                      child: hasAddress
                          ? SelectableText(
                              space.address,
                              style: textTheme.bodyLarge,
                            )
                          : Text(
                              'Address is not available for this '
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
