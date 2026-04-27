import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/review.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/study_space_reviews_repository.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/utils/review_rating_labels.dart';
import 'package:cmpe_137_study_space/widgets/review_modal_content.dart';

String _formatReviewDate(Timestamp? ts) {
  if (ts == null) return 'Recently';
  final d = ts.toDate();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class SpaceReviewsSection extends StatefulWidget {
  final StudySpace space;
  final Future<void> Function()? onReviewsMutated;

  const SpaceReviewsSection({
    super.key,
    required this.space,
    this.onReviewsMutated,
  });

  @override
  State<SpaceReviewsSection> createState() => _SpaceReviewsSectionState();
}

class _SpaceReviewsSectionState extends State<SpaceReviewsSection> {
  late Stream<List<Review>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = StudySpaceReviewsRepository()
        .watchReviewsForSpace(widget.space.id);
  }

  @override
  void didUpdateWidget(covariant SpaceReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.space.id != widget.space.id) {
      setState(() {
        _reviewsStream = StudySpaceReviewsRepository()
            .watchReviewsForSpace(widget.space.id);
      });
    }
  }

  void _openEditSheet(Review review) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ReviewModalContent(
          space: widget.space,
          existingReview: review,
          onReviewSubmitted: widget.onReviewsMutated,
        );
      },
    );
  }

  Future<void> _confirmAndDelete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This removes your review from this study space. You can leave a new '
          'review later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await StudySpaceReviewsRepository().deleteReview(
        spaceId: widget.space.id,
        reviewId: review.id,
      );
      if (mounted) {
        await AuthScope.of(context).decrementReviewCount();
      }
      if (widget.onReviewsMutated != null) {
        await widget.onReviewsMutated!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Review>>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load reviews. ${snapshot.error}',
                style: textTheme.bodyMedium?.copyWith(color: Colors.red.shade800),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final reviews = snapshot.data!;

        if (reviews.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No reviews yet. Be the first to share how this space worked for you.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final isOwn = currentUid != null && currentUid == review.userId;
            return _ReviewTile(
              review: review,
              formattedDate: _formatReviewDate(review.createdAt),
              isOwnReview: isOwn,
              onEdit: isOwn ? () => _openEditSheet(review) : null,
              onDelete: isOwn ? () => _confirmAndDelete(review) : null,
            );
          },
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final String formattedDate;
  final bool isOwnReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewTile({
    required this.review,
    required this.formattedDate,
    required this.isOwnReview,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comment = review.comment.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.sjsuBlue.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.sjsuBlue,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName.isNotEmpty
                            ? review.userName
                            : 'Student',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnReview && onEdit != null && onDelete != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit review',
                        icon: const Icon(Icons.edit_outlined, size: 22),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Delete review',
                        icon: Icon(Icons.delete_outline, size: 22, color: Colors.red.shade700),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NoiseChip(level: review.noiseLevel),
                _MiniChip(label: 'Comfort', value: review.comfort),
                _MiniChip(label: 'Crowd', value: review.crowdLevel),
                _MiniChip(label: 'Access', value: review.easeOfAccess),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'No written comment.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoiseChip extends StatelessWidget {
  final int level;

  const _NoiseChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Noise: ${noiseLevelLabel(level)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final int value;

  const _MiniChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value/5',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
