import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/box.dart';
import '../providers/box_list_provider.dart';

/// Opens a dialog to add a new box.
Future<void> showAddBoxDialog(BuildContext context) {
  return showBoxFormDialog(context);
}

/// Opens a dialog to edit an existing box.
Future<void> showEditBoxDialog(BuildContext context, Box box) {
  return showBoxFormDialog(context, existing: box);
}

/// Manual dimension entry (placeholder until CV/Camera module).
Future<void> showBoxFormDialog(BuildContext context, {Box? existing}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _BoxFormDialog(
      dialogContext: dialogContext,
      existing: existing,
    ),
  );
}

class _BoxFormDialog extends ConsumerStatefulWidget {
  const _BoxFormDialog({
    required this.dialogContext,
    this.existing,
  });

  final BuildContext dialogContext;
  final Box? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<_BoxFormDialog> createState() => _BoxFormDialogState();
}

class _BoxFormDialogState extends ConsumerState<_BoxFormDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _depthController;
  late final TextEditingController _wallController;
  late final TextEditingController _labelController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final box = widget.existing;
    _widthController = TextEditingController(
      text: box != null ? _trimNum(box.width) : null,
    );
    _heightController = TextEditingController(
      text: box != null ? _trimNum(box.height) : null,
    );
    _depthController = TextEditingController(
      text: box != null ? _trimNum(box.depth) : null,
    );
    _wallController = TextEditingController(
      text: box != null ? _trimNum(box.wallThickness) : '0',
    );
    _labelController = TextEditingController(text: box?.label ?? '');
  }

  String _trimNum(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _wallController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final w = double.parse(_widthController.text);
    final h = double.parse(_heightController.text);
    final d = double.parse(_depthController.text);
    final wall = _wallController.text.isEmpty
        ? 0.0
        : double.parse(_wallController.text);
    if (wall * 2 >= w || wall * 2 >= h || wall * 2 >= d) {
      ScaffoldMessenger.of(widget.dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Wall thickness is too large for these dimensions'),
        ),
      );
      return;
    }

    final label = _labelController.text.trim().isEmpty
        ? null
        : _labelController.text.trim();
    final notifier = ref.read(boxListProvider.notifier);

    if (widget.isEditing) {
      notifier.updateBox(
        id: widget.existing!.id,
        width: w,
        height: h,
        depth: d,
        wallThickness: wall,
        label: label,
      );
    } else {
      notifier.addBox(
        width: w,
        height: h,
        depth: d,
        wallThickness: wall,
        label: label,
      );
    }

    ref.read(nestingResultProvider.notifier).state = null;
    Navigator.pop(widget.dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit box' : 'Add box'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g. Books',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _widthController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Width (cm)',
                ),
                validator: _positiveValidator,
              ),
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                ),
                validator: _positiveValidator,
              ),
              TextFormField(
                controller: _depthController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Depth (cm)',
                ),
                validator: _positiveValidator,
              ),
              TextFormField(
                controller: _wallController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Wall thickness (cm)',
                  helperText: 'Reduces inner cavity for nesting',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Enter a non-negative number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(widget.dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSubmit,
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

String? _positiveValidator(String? value) {
  if (value == null || value.isEmpty) return 'Required';
  final n = double.tryParse(value);
  if (n == null || n <= 0) return 'Enter a positive number';
  return null;
}
