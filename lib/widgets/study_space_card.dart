import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';

class StudySpaceCard extends StatelessWidget {
  final StudySpace space;

  const StudySpaceCard({
    super.key,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to space details screen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Image (we'll replace this with real images later)
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 50,
                  color: Colors.grey,
                ),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.sjsuGold, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            space.rating.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
