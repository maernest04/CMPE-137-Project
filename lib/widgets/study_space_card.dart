import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/review_service.dart';

class StudySpaceCard extends StatelessWidget {
  final StudySpace space;
  final Future<void> Function()? onReviewSubmitted;

  const StudySpaceCard({
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showLeaveReviewModal(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Image (we'll replace this with real images later)
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.image_outlined, size: 50, color: Colors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          space.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.sjsuGold,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            space.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    space.building,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter tags
                  Row(
                    children: [
                      _buildTag(
                        context,
                        icon: Icons.volume_up,
                        label: space.noiseLevel,
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade900,
                      ),
                      const SizedBox(width: 8),
                      if (space.hasOutlets)
                        _buildTag(
                          context,
                          icon: Icons.electrical_services,
                          label: 'Outlets',
                          color: Colors.green.shade100,
                          textColor: Colors.green.shade900,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget to properly manage TextEditingController lifecycle
class ReviewModalContent extends StatefulWidget {
  final StudySpace space;
  final Future<void> Function()? onReviewSubmitted;

  const ReviewModalContent({
    super.key,
    required this.space,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewModalContent> createState() => _ReviewModalContentState();
}

class _ReviewModalContentState extends State<ReviewModalContent> {
  late TextEditingController _commentController;
  double _rating = 3;
  double _vibe = 3;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _emojiFor(double value) {
    final index = value.clamp(1, 5).round() - 1;
    const emojis = ['😡', '😕', '😐', '🙂', '😄'];
    return emojis[index];
  }

  Future<void> _submitReview() async {
    try {
      final reviewService = ReviewService();

      await reviewService.submitReview(
        spaceId: widget.space.id,
        noiseLevel: _vibe.round(),
        comfort: _rating.round(),
        crowdLevel: 3, // temporary default
        easeOfAccess: 3, // temporary default
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (widget.onReviewSubmitted != null) {
        await widget.onReviewSubmitted!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thanks for your review of ${widget.space.name}! 👍',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leave a review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.space.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'How was it?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _emojiFor(_rating),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.round().toString(),
                    onChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Noise level',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _emojiFor(_vibe),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _vibe,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _vibe.round().toString(),
                    onChanged: (value) {
                      setState(() => _vibe = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Add a comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                child: const Text('Submit review'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
