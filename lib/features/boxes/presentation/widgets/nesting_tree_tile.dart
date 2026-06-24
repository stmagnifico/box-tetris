import 'package:flutter/material.dart';

import '../../../../core/utils/volume_formatter.dart';
import '../../domain/entities/nesting_node.dart';

/// Expandable tree row for one nesting branch (no Material dividers).
class NestingTreeTile extends StatefulWidget {
  const NestingTreeTile({
    super.key,
    required this.node,
    this.depth = 0,
  });

  final NestingNode node;
  final int depth;

  @override
  State<NestingTreeTile> createState() => _NestingTreeTileState();
}

class _NestingTreeTileState extends State<NestingTreeTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.depth == 0;
  }

  String _boxTitle() {
    final label = widget.node.box.label;
    final dims =
        '${widget.node.box.width}×${widget.node.box.height}×${widget.node.box.depth}';
    if (label != null && label.isNotEmpty) {
      return '$label ($dims)';
    }
    return 'Box $dims';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = widget.depth == 0;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
    );

    if (widget.node.children.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.fromLTRB(
          16 + widget.depth * 16.0,
          4,
          16,
          4,
        ),
        leading: Icon(
          isRoot ? Icons.inventory_2_outlined : Icons.subdirectory_arrow_right,
          size: 20,
          color: isRoot ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(_boxTitle(), style: titleStyle),
        subtitle: isRoot
            ? Text('Occupied volume: ${formatVolume(widget.node.occupiedVolume)}')
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.fromLTRB(
            8 + widget.depth * 8.0,
            0,
            8,
            0,
          ),
          leading: Icon(
            isRoot ? Icons.inventory_2 : Icons.folder_outlined,
            color: isRoot ? theme.colorScheme.primary : null,
          ),
          title: Text(_boxTitle(), style: titleStyle),
          subtitle: isRoot
              ? Text('Occupied volume: ${formatVolume(widget.node.occupiedVolume)}')
              : Text(
                  '${formatVolume(widget.node.box.volume)} · '
                  '${widget.node.children.length} nested',
                ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...widget.node.children.map(
            (child) => NestingTreeTile(node: child, depth: widget.depth + 1),
          ),
      ],
    );
  }
}
