import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../application/app_providers.dart';
import '../../application/petji_analytics.dart';
import '../../domain/models.dart';
import '../formatters.dart';
import '../theme/petji_theme.dart';
import '../widgets/breed_selector.dart';
import '../widgets/info_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
    this.onOpenTimelineEvent,
    this.onOpenTimelineAll,
  });

  final ValueChanged<String>? onOpenTimelineEvent;
  final VoidCallback? onOpenTimelineAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appSnapshotProvider);
    final controller = ref.read(appSnapshotProvider.notifier);
    final pet = snapshot.currentPet;
    if (pet == null) {
      return const Center(child: Text('请先登记宠物'));
    }

    final now = snapshot.exportedAt;
    final summary = summarizeMonthlyExpenses(
      snapshot.expenses.where(
        (entry) => entry.petId == null || entry.petId == pet.id,
      ),
      year: now.year,
      month: now.month,
    );
    final latestWeight =
        snapshot.weightRecords
            .where(
              (record) => record.petId == pet.id && record.deletedAt == null,
            )
            .toList()
          ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final vaccineCount = snapshot.records
        .where(
          (record) =>
              record.petId == pet.id &&
              record.category == CareCategory.vaccine &&
              record.deletedAt == null,
        )
        .length;
    final timelineItems =
        snapshot.timelineEvents
            .where((event) => event.petId == pet.id && event.deletedAt == null)
            .toList()
          ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '健康概览',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('宠物记', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '健康、成长和消费，一处长期记录',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Semantics(
              label: '切换宠物 ${pet.name}',
              button: true,
              child: IconButton(
                onPressed: () => _showPetSwitcher(context, ref, snapshot),
                tooltip: '切换宠物 ${pet.name}',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  fixedSize: const Size.square(58),
                ),
                icon: CircleAvatar(
                  radius: 28,
                  backgroundColor: PetjiColors.primary.withValues(alpha: 0.16),
                  backgroundImage: pet.avatarPath == null
                      ? null
                      : FileImage(File(pet.avatarPath!)),
                  child: pet.avatarPath == null
                      ? const Icon(
                          Icons.pets,
                          color: PetjiColors.primary,
                          size: 30,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PetHeader(
          pet: pet,
          asOf: now,
          onChangeAvatar: () => _showAvatarDialog(context, ref, pet),
          onEditProfile: () =>
              _showPetProfileDialog(context, ref, initialPet: pet),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  width: width,
                  label: '年龄',
                  value: pet.ageLabel(now),
                  icon: Icons.cake_outlined,
                ),
                _MetricCard(
                  width: width,
                  label: '体重',
                  value: latestWeight.isEmpty
                      ? '未记录'
                      : '${(latestWeight.first.grams / 1000).toStringAsFixed(1)}kg',
                  icon: Icons.monitor_weight_outlined,
                ),
                _MetricCard(
                  width: width,
                  label: '疫苗',
                  value: '$vaccineCount次',
                  helper: pet.isNeutered ? '已绝育' : '未绝育',
                  icon: Icons.vaccines_outlined,
                ),
                _MetricCard(
                  width: width,
                  label: '本月消费',
                  value: moneyLabel(summary.totalCents),
                  icon: Icons.payments_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '快捷记录',
          icon: Icons.add_task_outlined,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickButton(
                label: '体重',
                icon: Icons.monitor_weight_outlined,
                onPressed: () => _showWeightDialog(context, ref),
              ),
              _QuickButton(
                label: '喂食',
                icon: Icons.restaurant_outlined,
                onPressed: () => _showFeedingDialog(context, controller),
              ),
              _QuickButton(
                label: '疫苗/驱虫',
                icon: Icons.health_and_safety_outlined,
                onPressed: () => _showCareDialog(context, controller, now),
              ),
              _QuickButton(
                label: '体检报告',
                icon: Icons.description_outlined,
                onPressed: () => _showReportDialog(context, controller, now),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '最近动态',
          icon: Icons.auto_awesome_motion_outlined,
          child: timelineItems.isEmpty
              ? const Text('还没有成长记录')
              : Column(
                  children: [
                    for (final event in timelineItems.take(5))
                      _TimelinePreviewItem(
                        event: event,
                        onTap: () => onOpenTimelineEvent?.call(event.id),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onOpenTimelineAll,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('查看全部'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showPetSwitcher(
    BuildContext context,
    WidgetRef ref,
    AppSnapshot snapshot,
  ) {
    final pets = snapshot.pets.where((pet) => pet.deletedAt == null).toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text('切换宠物', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final item in pets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: PetjiColors.primary.withValues(
                      alpha: 0.14,
                    ),
                    backgroundImage: item.avatarPath == null
                        ? null
                        : FileImage(File(item.avatarPath!)),
                    child: item.avatarPath == null
                        ? const Icon(Icons.pets_outlined)
                        : null,
                  ),
                  title: Text(item.name),
                  subtitle: Text(item.ageLabel(snapshot.exportedAt)),
                  trailing: item.id == snapshot.activePetId
                      ? const Icon(Icons.check_circle, color: PetjiColors.cta)
                      : null,
                  onTap: () {
                    ref
                        .read(appSnapshotProvider.notifier)
                        .switchActivePet(item.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _showPetProfileDialog(context, ref);
                },
                icon: const Icon(Icons.add),
                label: const Text('新增宠物'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: snapshot.currentPet == null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _showDeletePetConfirmation(
                          context,
                          ref,
                          snapshot.currentPet!,
                        );
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除档案'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPetProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    PetProfile? initialPet,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _PetProfileDialog(
        initialPet: initialPet,
        onPickAvatar: _pickManagedAvatar,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onSave: (draft) {
          final controller = ref.read(appSnapshotProvider.notifier);
          if (initialPet == null) {
            final pet = controller.registerPet(
              name: draft.name,
              species: draft.species,
              breed: draft.breed,
              birthday: draft.birthday,
              sex: draft.sex,
              isNeutered: draft.isNeutered,
              avatarPath: draft.avatarPath,
              notes: draft.notes,
            );
            controller.switchActivePet(pet.id);
            Navigator.of(dialogContext).pop();
            _showMessage(context, '宠物档案已新增');
            return;
          }
          controller.updatePetProfile(
            petId: initialPet.id,
            name: draft.name,
            species: draft.species,
            breed: draft.breed,
            birthday: draft.birthday,
            sex: draft.sex,
            isNeutered: draft.isNeutered,
            notes: draft.notes,
          );
          Navigator.of(dialogContext).pop();
          _showMessage(context, '档案已更新');
        },
      ),
    );
  }

  Future<String?> _pickManagedAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return null;
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'petji', 'avatars'));
    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(picked.path)}',
      ),
    );
    await File(picked.path).copy(target.path);
    return target.path;
  }

  void _showAvatarDialog(BuildContext context, WidgetRef ref, PetProfile pet) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('更换头像'),
        content: Text('为 ${pet.name} 选择新的档案头像。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final path = await _pickManagedAvatar();
              if (path == null) {
                return;
              }
              ref
                  .read(appSnapshotProvider.notifier)
                  .updatePetAvatar(pet.id, path);
              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                _showMessage(context, '头像已更新');
              }
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('从相册选择'),
          ),
        ],
      ),
    );
  }

  void _showDeletePetConfirmation(
    BuildContext context,
    WidgetRef ref,
    PetProfile pet,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除档案'),
        content: Text('将永久删除 ${pet.name} 的档案、记录、待办和提醒。此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(appSnapshotProvider.notifier).deletePetHard(pet.id);
              Navigator.of(dialogContext).pop();
              _showMessage(context, '宠物档案已删除');
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, WidgetRef ref) {
    final input = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('记录体重'),
          content: Form(
            key: formKey,
            child: Semantics(
              label: '体重公斤输入框',
              textField: true,
              child: TextFormField(
                controller: input,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '体重（kg）'),
                validator: (value) {
                  final kilograms = double.tryParse(value?.trim() ?? '');
                  return kilograms == null || kilograms <= 0 ? '请输入有效体重' : null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                ref
                    .read(appSnapshotProvider.notifier)
                    .addWeightKg(double.parse(input.text.trim()));
                Navigator.of(dialogContext).pop();
                _showMessage(context, '体重已保存');
              },
              child: const Text('保存体重'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedingDialog(BuildContext context, PetjiController controller) {
    final input = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('记录喂食'),
          content: Form(
            key: formKey,
            child: Semantics(
              label: '喂食克数输入框',
              textField: true,
              child: TextFormField(
                controller: input,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '克数（g）'),
                validator: (value) {
                  final grams = int.tryParse(value?.trim() ?? '');
                  return grams == null || grams <= 0 ? '请输入有效克数' : null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final grams = int.parse(input.text.trim());
                controller.addFeeding(amountGrams: grams);
                Navigator.of(dialogContext).pop();
                _showMessage(context, '已记录${grams}g喂食');
              },
              child: const Text('保存喂食'),
            ),
          ],
        );
      },
    );
  }

  void _showCareDialog(
    BuildContext context,
    PetjiController controller,
    DateTime today,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CareDialog(
          initialDate: DateTime(today.year, today.month, today.day),
          onPickImage: () => _pickManagedImage('care-media'),
          onSave: (category, date, mediaPath) {
            controller.addCare(
              category,
              date: date,
              mediaPath: mediaPath,
              title: careCategoryLabel(category),
            );
            Navigator.of(dialogContext).pop();
            _showMessage(context, '护理记录已保存');
          },
        );
      },
    );
  }

  void _showReportDialog(
    BuildContext context,
    PetjiController controller,
    DateTime today,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ReportDialog(
          initialDate: DateTime(today.year, today.month, today.day),
          onPickFile: () => _pickManagedFile('reports'),
          onSave: (date, filePath) {
            controller.addCare(
              CareCategory.report,
              date: date,
              filePath: filePath,
              title: '体检报告',
            );
            Navigator.of(dialogContext).pop();
            _showMessage(context, filePath == null ? '已保存体检报告记录' : '体检报告已保存');
          },
        );
      },
    );
  }

  Future<String?> _pickManagedImage(String directoryName) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return null;
    }
    return _copyManagedFile(picked.path, directoryName);
  }

  Future<String?> _pickManagedFile(String directoryName) async {
    final file = await openFile();
    if (file == null) {
      return null;
    }
    return _copyManagedFile(file.path, directoryName);
  }

  Future<String> _copyManagedFile(
    String sourcePath,
    String directoryName,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'petji', directoryName));
    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(sourcePath)}',
      ),
    );
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PetProfileDraft {
  const _PetProfileDraft({
    required this.name,
    required this.species,
    required this.breed,
    required this.birthday,
    required this.sex,
    required this.isNeutered,
    required this.avatarPath,
    required this.notes,
  });

  final String name;
  final PetSpecies species;
  final String breed;
  final DateTime birthday;
  final PetSex sex;
  final bool isNeutered;
  final String? avatarPath;
  final String? notes;
}

class _PetProfileDialog extends StatefulWidget {
  const _PetProfileDialog({
    required this.onPickAvatar,
    required this.onCancel,
    required this.onSave,
    this.initialPet,
  });

  final PetProfile? initialPet;
  final Future<String?> Function() onPickAvatar;
  final VoidCallback onCancel;
  final ValueChanged<_PetProfileDraft> onSave;

  @override
  State<_PetProfileDialog> createState() => _PetProfileDialogState();
}

class _PetProfileDialogState extends State<_PetProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late PetSpecies _species;
  late String _breed;
  late DateTime _birthday;
  late PetSex _sex;
  late bool _isNeutered;
  late String? _avatarPath;

  bool get _isEditing => widget.initialPet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.initialPet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _notesController = TextEditingController(text: pet?.notes ?? '');
    _species = pet?.species ?? PetSpecies.cat;
    _breed = pet?.breed ?? '';
    _birthday = pet?.birthday ?? DateTime.now();
    _sex = pet?.sex ?? PetSex.unknown;
    _isNeutered = pet?.isNeutered ?? false;
    _avatarPath = pet?.avatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑宠物档案' : '新增宠物'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing) ...[
                OutlinedButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(_avatarPath == null ? '选择头像' : '已选择头像'),
                ),
                const SizedBox(height: 12),
              ],
              Semantics(
                label: '宠物姓名输入框',
                textField: true,
                child: TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '宠物姓名'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请填写宠物姓名' : null,
                ),
              ),
              const SizedBox(height: 12),
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
                  setState(() {
                    _species = selection.first;
                    _breed = '';
                  });
                },
              ),
              const SizedBox(height: 12),
              BreedSelector(
                key: ValueKey(_species),
                species: _species,
                initialBreed: _breed,
                onChanged: (value) => _breed = value,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickBirthday,
                icon: const Icon(Icons.cake_outlined),
                label: Text('生日 ${dateLabel(_birthday)}'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<PetSex>(
                segments: const [
                  ButtonSegment(value: PetSex.unknown, label: Text('未知')),
                  ButtonSegment(value: PetSex.male, label: Text('公')),
                  ButtonSegment(value: PetSex.female, label: Text('母')),
                ],
                selected: {_sex},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _sex = selection.first),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('已绝育'),
                value: _isNeutered,
                onChanged: (value) =>
                    setState(() => _isNeutered = value ?? false),
              ),
              Semantics(
                label: '宠物备注输入框',
                textField: true,
                child: TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('取消')),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? '保存修改' : '保存宠物档案'),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final path = await widget.onPickAvatar();
    if (mounted && path != null) {
      setState(() => _avatarPath = path);
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
    final notes = _notesController.text.trim();
    widget.onSave(
      _PetProfileDraft(
        name: _nameController.text,
        species: _species,
        breed: _breed,
        birthday: _birthday,
        sex: _sex,
        isNeutered: _isNeutered,
        avatarPath: _avatarPath,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }
}

class _CareDialog extends StatefulWidget {
  const _CareDialog({
    required this.initialDate,
    required this.onPickImage,
    required this.onSave,
  });

  final DateTime initialDate;
  final Future<String?> Function() onPickImage;
  final void Function(CareCategory category, DateTime date, String? mediaPath)
  onSave;

  @override
  State<_CareDialog> createState() => _CareDialogState();
}

class _CareDialogState extends State<_CareDialog> {
  late DateTime _date = widget.initialDate;
  CareCategory _category = CareCategory.vaccine;
  String? _mediaPath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('疫苗/驱虫'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<CareCategory>(
              segments: const [
                ButtonSegment(
                  value: CareCategory.vaccine,
                  label: Text('疫苗'),
                  icon: Icon(Icons.vaccines_outlined),
                ),
                ButtonSegment(
                  value: CareCategory.deworming,
                  label: Text('驱虫'),
                  icon: Icon(Icons.health_and_safety_outlined),
                ),
              ],
              selected: {_category},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _category = selection.first),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  confirmText: '确定',
                  cancelText: '取消',
                );
                if (selected != null) {
                  setState(() => _date = selected);
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(dateLabel(_date)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final path = await widget.onPickImage();
                if (mounted && path != null) {
                  setState(() => _mediaPath = path);
                }
              },
              icon: const Icon(Icons.image_outlined),
              label: Text(_mediaPath == null ? '选择凭证图片' : '已选择凭证图片'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => widget.onSave(_category, _date, _mediaPath),
          child: const Text('保存护理'),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.initialDate,
    required this.onPickFile,
    required this.onSave,
  });

  final DateTime initialDate;
  final Future<String?> Function() onPickFile;
  final void Function(DateTime date, String? filePath) onSave;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  late DateTime _date = widget.initialDate;
  String? _filePath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('体检报告'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                confirmText: '确定',
                cancelText: '取消',
              );
              if (selected != null) {
                setState(() => _date = selected);
              }
            },
            icon: const Icon(Icons.event_outlined),
            label: Text(dateLabel(_date)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final path = await widget.onPickFile();
              if (mounted && path != null) {
                setState(() => _filePath = path);
              }
            },
            icon: const Icon(Icons.attach_file),
            label: Text(_filePath == null ? '选择报告文件' : '已选择报告文件'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => widget.onSave(_date, _filePath),
          child: const Text('保存报告'),
        ),
      ],
    );
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({
    required this.pet,
    required this.asOf,
    required this.onChangeAvatar,
    required this.onEditProfile,
  });

  final PetProfile pet;
  final DateTime asOf;
  final VoidCallback onChangeAvatar;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '宠物档案 ${pet.name}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PetjiColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Semantics(
              label: '更换 ${pet.name} 头像',
              button: true,
              child: InkWell(
                onTap: onChangeAvatar,
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      backgroundImage: pet.avatarPath == null
                          ? null
                          : FileImage(File(pet.avatarPath!)),
                      child: pet.avatarPath == null
                          ? const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 34,
                            )
                          : null,
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: PetjiColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed.isEmpty ? '未填写品种' : pet.breed} · ${pet.ageLabel(asOf)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Semantics(
              label: '编辑 ${pet.name} 基本信息',
              button: true,
              child: IconButton(
                onPressed: onEditProfile,
                tooltip: '编辑 ${pet.name} 基本信息',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: [label, value, if (helper != null) helper].join(' '),
      child: SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: PetjiColors.cta),
                const SizedBox(height: 10),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                if (helper != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helper!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _TimelinePreviewItem extends StatelessWidget {
  const _TimelinePreviewItem({required this.event, required this.onTap});

  final TimelineEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: PetjiColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 2, height: 38, color: const Color(0xFFFFEDD5)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateLabel(event.happenedAt)} · ${timelineEventTypeLabel(event.type)}',
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
