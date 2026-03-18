import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/study_space.dart';

class StudySpaceCard extends StatelessWidget {
  final StudySpace space;

  const StudySpaceCard({
    super.key,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
            // TODO: Navigate to detail screen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (In reality, this would be a NetworkImage)
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 60, color: Colors.grey),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          space.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sjsuBlue,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sjsuGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: AppTheme.sjsuGold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              space.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Building Name
                  Text(
                    space.building,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tags/Features Row
                  Row(
                    children: [
                      _buildFeatureTag(
                        icon: Icons.volume_up, 
                        text: space.noiseLevel,
                        color: space.noiseLevel == 'Quiet' ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      if (space.hasOutlets)
                        _buildFeatureTag(
                          icon: Icons.electrical_services, 
                          text: 'Outlets',
                          color: AppTheme.sjsuBlue,
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

  Widget _buildFeatureTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
