import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/optimization_runner.dart';
import '../providers/box_list_provider.dart';
import '../widgets/optimization_loading_overlay.dart';
import 'box_form_dialog.dart';
import 'results_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isOptimizing = false;

  String _formatVolume(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(2)} m³';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)} L';
    }
    return '${v.toStringAsFixed(0)} cm³';
  }

  Future<void> _runOptimization() async {
    if (_isOptimizing) return;

    final boxes = ref.read(boxListProvider);
    setState(() => _isOptimizing = true);

    // Let the overlay paint before heavy work starts.
    await Future<void>.delayed(Duration.zero);

    try {
      final result = await runOptimization(boxes);
      if (!mounted) return;
      ref.read(nestingResultProvider.notifier).state = result;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ResultsScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = ref.watch(boxListProvider);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Box Tetris'),
            actions: [
              if (boxes.isNotEmpty)
                IconButton(
                  tooltip: 'Clear all',
                  onPressed: _isOptimizing
                      ? null
                      : () {
                          ref.read(boxListProvider.notifier).clear();
                          ref.read(nestingResultProvider.notifier).state = null;
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: boxes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No boxes yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add box dimensions manually.\n'
                          'Camera / CV input coming in a later module.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: boxes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final box = boxes[index];
                    final label = box.label;
                    return Card(
                      child: ListTile(
                        onTap: _isOptimizing
                            ? null
                            : () => showEditBoxDialog(context, box),
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          label ?? 'Box ${index + 1}',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${box.width} × ${box.height} × ${box.depth} cm'
                          '${box.wallThickness > 0 ? '\nWall: ${box.wallThickness} cm' : ''}'
                          '\nVolume: ${_formatVolume(box.volume)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _isOptimizing
                                  ? null
                                  : () => showEditBoxDialog(context, box),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close),
                              onPressed: _isOptimizing
                                  ? null
                                  : () {
                                      ref
                                          .read(boxListProvider.notifier)
                                          .removeBox(box.id);
                                      ref
                                          .read(nestingResultProvider.notifier)
                                          .state = null;
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: boxes.isEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _isOptimizing ? null : () => showAddBoxDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add box'),
                    ),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isOptimizing ? null : _runOptimization,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Calculate optimization'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isOptimizing ? null : () => showAddBoxDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add box'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_isOptimizing) const OptimizationLoadingOverlay(),
      ],
    );
  }
}
