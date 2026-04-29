import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/screens/study_space_detail_screen.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/user_reviews_repository.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/utils/review_rating_labels.dart';

String _formatReviewDate(Timestamp? ts) {
  if (ts == null) return '';
  final d = ts.toDate();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Lists the signed-in user's reviews and links each row to the study space detail.
class ProfileMyReviewsSection extends StatefulWidget {
  const ProfileMyReviewsSection({super.key});

  @override
  State<ProfileMyReviewsSection> createState() => _ProfileMyReviewsSectionState();
}

class _ProfileMyReviewsSectionState extends State<ProfileMyReviewsSection> {
  StreamSubscription<List<UserReviewEntry>>? _sub;
  List<UserReviewEntry> _entries = [];
  Map<String, String> _spaceNames = {};
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _sub = UserReviewsRepository().watchReviewsForUser(uid).listen(
      (list) => _onReviewsUpdated(list),
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e;
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _onReviewsUpdated(List<UserReviewEntry> list) async {
    final ids = list.map((e) => e.spaceId).toSet();
    final names = <String, String>{..._spaceNames};
    try {
      await Future.wait(ids.map((id) async {
        if (names.containsKey(id) && names[id]!.isNotEmpty) return;
        final doc = await FirebaseFirestore.instance
            .collection('spaces')
            .doc(id)
            .get();
        if (doc.exists) {
          final n = doc.data()?['name'] as String?;
          names[id] = (n != null && n.isNotEmpty) ? n : 'Study space';
        } else {
          names[id] = 'Study space';
        }
      }));
    } catch (_) {
      for (final id in ids) {
        names.putIfAbsent(id, () => 'Study space');
      }
    }
    if (!mounted) return;
    setState(() {
      _entries = list;
      _spaceNames = names;
      _loading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openSpaceDetail(UserReviewEntry entry) async {
    final doc = await FirebaseFirestore.instance
        .collection('spaces')
        .doc(entry.spaceId)
        .get();
    if (!mounted) return;
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That study space is no longer available.')),
      );
      return;
    }
    final space = StudySpace.fromFirestore(doc);
    final auth = AuthScope.of(context);
    await context.pushNamed(
      'studySpaceDetailRoot',
      pathParameters: {'id': space.id},
      extra: StudySpaceDetailArgs(
        space: space,
        onReviewSubmitted: () async {
          await auth.refreshUserProfileFromServer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Could not load your reviews.',
          style: textTheme.bodySmall?.copyWith(color: Colors.red.shade800),
        ),
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'You have not posted any reviews yet.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in _entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 1,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openSpaceDetail(entry),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _spaceNames[entry.spaceId] ?? 'Study space',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sjsuBlue,
                        ),
                      ),
                      if (_formatReviewDate(entry.review.createdAt).isNotEmpty)
                        Text(
                          _formatReviewDate(entry.review.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '★ ${entry.review.overallRating}/5 · '
                        'Noise: ${noiseLevelLabel(entry.review.noiseLevel)} · '
                        'Comfort ${entry.review.comfort}/5 · '
                        'Crowd ${entry.review.crowdLevel}/5 · '
                        'Access ${entry.review.easeOfAccess}/5',
                        style: textTheme.bodySmall,
                      ),
                      if (entry.review.comment.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.review.comment.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Tap to open study space',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
