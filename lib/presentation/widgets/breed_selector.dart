import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/pet_breeds.dart';

class BreedSelector extends StatefulWidget {
  const BreedSelector({
    super.key,
    required this.species,
    required this.onChanged,
    this.initialBreed = '',
  });

  final PetSpecies species;
  final String initialBreed;
  final ValueChanged<String> onChanged;

  @override
  State<BreedSelector> createState() => _BreedSelectorState();
}

class _BreedSelectorState extends State<BreedSelector> {
  final _customController = TextEditingController();
  String? _selected;

  @override
  void initState() {
    super.initState();
    _applyInitialBreed(widget.initialBreed);
  }

  @override
  void didUpdateWidget(BreedSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      _selected = null;
      _customController.clear();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = breedOptionsFor(widget.species);
    final selected = _selected != null && options.contains(_selected)
        ? _selected
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: '品种（可选）'),
          hint: const Text('选择品种'),
          items: options
              .map(
                (breed) => DropdownMenuItem(value: breed, child: Text(breed)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selected = value);
            widget.onChanged(
              value == customBreedOption
                  ? _customController.text.trim()
                  : value,
            );
          },
        ),
        if (_selected == customBreedOption) ...[
          const SizedBox(height: 12),
          Semantics(
            label: '自定义品种输入框',
            textField: true,
            child: TextFormField(
              controller: _customController,
              decoration: const InputDecoration(labelText: '自定义品种'),
              onChanged: (value) => widget.onChanged(value.trim()),
            ),
          ),
        ],
      ],
    );
  }

  void _applyInitialBreed(String breed) {
    final trimmed = breed.trim();
    if (trimmed.isEmpty) {
      _selected = null;
      return;
    }
    final options = breedOptionsFor(widget.species);
    if (options.contains(trimmed)) {
      _selected = trimmed;
      return;
    }
    _selected = customBreedOption;
    _customController.text = trimmed;
  }
}
