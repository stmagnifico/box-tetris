import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/nesting_node.dart';
import '../providers/box_list_provider.dart';
import '../widgets/nesting_tree_tile.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  String _formatVolume(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(3)} m³';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)} L';
    }
    return '${v.toStringAsFixed(0)} cm³';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(nestingResultProvider);
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No optimization result')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimization result'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'Original total volume',
                    value: _formatVolume(result.originalTotalVolume),
                  ),
                  _StatRow(
                    label: 'Optimized footprint',
                    value: _formatVolume(result.optimizedTotalVolume),
                  ),
                  _StatRow(
                    label: 'Space saved',
                    value:
                        '${_formatVolume(result.savedVolume)} (${result.savedPercent.toStringAsFixed(1)}%)',
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.rootCount} outer container(s) on shelf',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nesting structure',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (result.roots.isEmpty)
            const Text('No boxes to display')
          else
            ...result.roots.map(
              (NestingNode root) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: NestingTreeTile(node: root),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
