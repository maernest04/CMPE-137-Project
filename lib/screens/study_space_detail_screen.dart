import 'dart:async';

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

  const StudySpaceDetailArgs({required this.space, this.onReviewSubmitted});
}

class StudySpaceDetailScreen extends StatefulWidget {
  final StudySpace? initialSpace;
  final String spaceId;
  final Future<void> Function()? onReviewSubmitted;

  const StudySpaceDetailScreen({
    super.key,
    this.initialSpace,
    required this.spaceId,
    this.onReviewSubmitted,
  });

  @override
  State<StudySpaceDetailScreen> createState() => _StudySpaceDetailScreenState();
}

class _StudySpaceDetailScreenState extends State<StudySpaceDetailScreen> {
  late StudySpace? _space;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<StudySpace?>? _spaceSubscription;

  @override
  void initState() {
    super.initState();
    _space = widget.initialSpace;
    _watchSpace();
    if (_space == null) {
      _loadSpace();
    }
  }

  @override
  void dispose() {
    _spaceSubscription?.cancel();
    super.dispose();
  }

  void _watchSpace() {
    _spaceSubscription = StudySpaceService.instance
        .watchStudySpaceById(widget.spaceId)
        .listen(
          (space) {
            if (!mounted) return;
            setState(() {
              _space = space;
              _isLoading = false;
              _errorMessage = null;
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() {
              _errorMessage = e.toString();
              _isLoading = false;
            });
          },
        );
  }

  Future<void> _loadSpace() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final space = await StudySpaceService.instance.fetchStudySpaceById(
        widget.spaceId,
      );
      if (mounted) {
        setState(() {
          _space = space;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showLeaveReviewModal(BuildContext context) {
    if (_space == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ReviewModalContent(
          space: _space!,
          onReviewSubmitted: _refreshAfterReviewMutation,
        );
      },
    );
  }

  Future<void> _refreshAfterReviewMutation() async {
    await _loadSpace();
    if (widget.onReviewSubmitted != null) {
      await widget.onReviewSubmitted!();
    }
  }

  Future<void> _confirmDelete() async {
    if (_space == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Space?'),
        content: const Text(
          'Are you sure you want to delete this study space? This action cannot be undone.',
        ),
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

    if (confirmed == true && mounted) {
      try {
        await StudySpaceService.instance.deleteStudySpace(_space!.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Study space deleted.')));

          context.pop();

          if (widget.onReviewSubmitted != null) {
            await widget.onReviewSubmitted!();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete space: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _space == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Space')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'This space could not be found.'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadSpace, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final space = _space!;
    final textTheme = Theme.of(context).textTheme;
    final hasAddress = space.address.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(space.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  const SnackBar(
                    content: Text('Sign in to save study spaces.'),
                  ),
                );
                return;
              }
              authService.toggleSavedSpace(space.id);
            },
          ),
          if (AuthScope.of(context).uid == space.createdBy &&
              space.createdBy.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: _confirmDelete,
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
              child: space.imageUrl != null
                  ? Image.network(
                      space.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
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
                        label: 'Noise: ${space.noiseLevel}',
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade900,
                      ),
                      _DetailTag(
                        icon: Icons.chair,
                        label:
                            'Comfort: ${space.comfortRating.toStringAsFixed(1)}/5',
                        color: Colors.orange.shade50,
                        textColor: Colors.orange.shade900,
                      ),
                      _DetailTag(
                        icon: Icons.groups,
                        label:
                            'Crowd: ${space.crowdRating.toStringAsFixed(1)}/5',
                        color: Colors.red.shade50,
                        textColor: Colors.red.shade900,
                      ),
                      _DetailTag(
                        icon: Icons.accessibility,
                        label:
                            'Access: ${space.accessRating.toStringAsFixed(1)}/5',
                        color: Colors.green.shade50,
                        textColor: Colors.green.shade900,
                      ),
                      if (space.floor != null && space.floor!.isNotEmpty)
                        _DetailTag(
                          icon: Icons.layers,
                          label: 'Floor: ${space.floor!}',
                          color: Colors.purple.shade50,
                          textColor: Colors.purple.shade900,
                        ),
                      if (space.hasOutlets)
                        _DetailTag(
                          icon: Icons.electrical_services,
                          label: 'Power outlets',
                          color: Colors.cyan.shade50,
                          textColor: Colors.cyan.shade900,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (space.floor != null ||
                              space.areaDescription != null) ...[
                            Text(
                              '${space.floor ?? ''}${space.floor != null && space.areaDescription != null ? ' - ' : ''}${space.areaDescription ?? ''}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            hasAddress
                                ? space.address
                                : 'One Washington Square, San Jose, CA 95192',
                            style: textTheme.bodyLarge,
                          ),
                        ],
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
                    onReviewsMutated: _refreshAfterReviewMutation,
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
