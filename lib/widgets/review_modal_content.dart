import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/review_service.dart';

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
        crowdLevel: 3,
        easeOfAccess: 3,
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
