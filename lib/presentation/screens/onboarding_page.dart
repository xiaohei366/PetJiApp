import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../application/app_providers.dart';
import '../../domain/models.dart';
import '../formatters.dart';
import '../theme/petji_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  PetSpecies _species = PetSpecies.cat;
  DateTime _birthday = DateTime.now();
  String? _avatarPath;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: PetjiColors.primary.withValues(alpha: 0.16),
                backgroundImage: _avatarPath == null
                    ? null
                    : FileImage(File(_avatarPath!)),
                child: _avatarPath == null
                    ? const Icon(
                        Icons.pets,
                        color: PetjiColors.primary,
                        size: 36,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '先登记你的宠物',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '姓名和生日用于生成年龄、提醒和成长线。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_avatarPath == null ? '选择头像' : '已选择头像'),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: '宠物名称输入框',
                        textField: true,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: '宠物姓名'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '请输入宠物姓名'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: '品种输入框',
                        textField: true,
                        child: TextFormField(
                          controller: _breedController,
                          decoration: const InputDecoration(
                            labelText: '品种（可选）',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<PetSpecies>(
                        segments: const [
                          ButtonSegment(
                            value: PetSpecies.cat,
                            label: Text('猫'),
                            icon: Icon(Icons.pets_outlined),
                          ),
                          ButtonSegment(
                            value: PetSpecies.dog,
                            label: Text('狗'),
                            icon: Icon(Icons.cruelty_free_outlined),
                          ),
                          ButtonSegment(
                            value: PetSpecies.other,
                            label: Text('其他'),
                            icon: Icon(Icons.favorite_border),
                          ),
                        ],
                        selected: {_species},
                        onSelectionChanged: (selection) {
                          setState(() => _species = selection.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: '出生日期选择框',
                        button: true,
                        child: OutlinedButton.icon(
                          onPressed: _pickBirthday,
                          icon: const Icon(Icons.cake_outlined),
                          label: Text('出生日期 ${dateLabel(_birthday)}'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('保存宠物档案'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final avatars = Directory(p.join(directory.path, 'petji', 'avatars'));
    await avatars.create(recursive: true);
    final target = File(
      p.join(
        avatars.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(picked.path)}',
      ),
    );
    await File(picked.path).copy(target.path);
    if (mounted) {
      setState(() => _avatarPath = target.path);
    }
  }

  Future<void> _pickBirthday() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      confirmText: '确定',
      cancelText: '取消',
    );
    if (selected != null) {
      setState(() => _birthday = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ref
        .read(appSnapshotProvider.notifier)
        .registerPet(
          name: _nameController.text,
          species: _species,
          breed: _breedController.text,
          birthday: _birthday,
          avatarPath: _avatarPath,
        );
  }
}
