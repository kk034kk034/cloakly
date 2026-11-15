import 'package:flutter/material.dart';

/// Fixed-height plan summary. Loading, ready, and error states share [height]
/// so account actions below the row stay put.
class CurrentPlanRow extends StatelessWidget {
  const CurrentPlanRow({
    required this.title,
    required this.status,
    required this.loading,
    required this.onTap,
    this.statusColor,
    super.key,
  });

  static const double height = 72;
  static const Key skeletonKey = Key('current-plan-skeleton');

  final String title;
  final String status;
  final bool loading;
  final VoidCallback? onTap;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: height,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const SizedBox(
              width: 40,
              child: Icon(Icons.workspace_premium_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 20,
                    child: loading
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              key: skeletonKey,
                              width: 148,
                              height: 12,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: statusColor ?? scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
