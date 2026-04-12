import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/review.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/review_service.dart';
import 'package:cmpe_137_study_space/services/study_space_reviews_repository.dart';
import 'package:cmpe_137_study_space/utils/review_rating_labels.dart';

class ReviewModalContent extends StatefulWidget {
  final StudySpace space;
  /// When set, the sheet edits this review (Firestore update) instead of creating.
  final Review? existingReview;
  final Future<void> Function()? onReviewSubmitted;

  const ReviewModalContent({
    super.key,
    required this.space,
    this.existingReview,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewModalContent> createState() => _ReviewModalContentState();
}

class _ReviewModalContentState extends State<ReviewModalContent> {
  late TextEditingController _commentController;
  late double _noise;
  late double _comfort;
  late double _crowd;
  late double _access;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingReview;
    _noise = (e?.noiseLevel ?? 3).toDouble().clamp(1, 5);
    _comfort = (e?.comfort ?? 3).toDouble().clamp(1, 5);
    _crowd = (e?.crowdLevel ?? 3).toDouble().clamp(1, 5);
    _access = (e?.easeOfAccess ?? 3).toDouble().clamp(1, 5);
    _commentController = TextEditingController(text: e?.comment ?? '');
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

  Future<void> _submit() async {
    try {
      final comment = _commentController.text.trim();
      final noise = _noise.round().clamp(1, 5);
      final comfort = _comfort.round().clamp(1, 5);
      final crowd = _crowd.round().clamp(1, 5);
      final access = _access.round().clamp(1, 5);

      if (_isEdit) {
        await StudySpaceReviewsRepository().updateReview(
          spaceId: widget.space.id,
          reviewId: widget.existingReview!.id,
          noiseLevel: noise,
          comfort: comfort,
          crowdLevel: crowd,
          easeOfAccess: access,
          comment: comment,
        );
      } else {
        await ReviewService().submitReview(
          spaceId: widget.space.id,
          noiseLevel: noise,
          comfort: comfort,
          crowdLevel: crowd,
          easeOfAccess: access,
          comment: comment,
        );
        if (mounted) {
          await AuthScope.of(context).incrementReviewCount();
        }
      }

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
              _isEdit
                  ? 'Review updated for ${widget.space.name}.'
                  : 'Thanks for your review of ${widget.space.name}! 👍',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Failed to update review: $e' : 'Failed to submit review: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _ratingSlider({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(_emojiFor(value), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                label: value.round().toString(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final noiseRounded = _noise.round().clamp(1, 5);

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
                  _isEdit ? 'Edit review' : 'Leave a review',
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
            const SizedBox(height: 20),
            _ratingSlider(
              title: 'Noise level',
              subtitle:
                  '1 = silent, 2 = quiet, 3 = moderate/calm, 4 = loud, 5 = very loud. '
                  'Current: ${noiseLevelLabel(noiseRounded)}',
              value: _noise,
              onChanged: (v) => setState(() => _noise = v),
            ),
            const SizedBox(height: 16),
            _ratingSlider(
              title: 'Comfort',
              subtitle: 'Seating, temperature, and how pleasant it is to work there (1–5).',
              value: _comfort,
              onChanged: (v) => setState(() => _comfort = v),
            ),
            const SizedBox(height: 16),
            _ratingSlider(
              title: 'Crowd level',
              subtitle: 'How busy or crowded it felt (1 = sparse, 5 = packed).',
              value: _crowd,
              onChanged: (v) => setState(() => _crowd = v),
            ),
            const SizedBox(height: 16),
            _ratingSlider(
              title: 'Ease of access',
              subtitle: 'How easy it was to get to and use the space (1–5).',
              value: _access,
              onChanged: (v) => setState(() => _access = v),
            ),
            const SizedBox(height: 16),
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
                onPressed: _submit,
                child: Text(_isEdit ? 'Save changes' : 'Submit review'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
