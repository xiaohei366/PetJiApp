import 'dart:io';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/app_providers.dart';
import '../../application/backup_bundle_service.dart';
import '../../domain/models.dart';
import '../widgets/info_card.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _bundleService = const BackupBundleService();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text('我的', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('本地优先保存宠物档案、待办、成长线和消费数据。'),
        const SizedBox(height: 18),
        InfoCard(
          title: '.petji 备份包',
          icon: Icons.archive_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导出或导入包含数据和附件索引的 Petji 备份包。导入会新增为独立宠物档案。'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _exportBundle,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('导出.petji包'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickImportBundle,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('导入.petji包'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportBundle() async {
    final snapshot = ref.read(appSnapshotProvider);
    try {
      final directory = await _backupDirectory();
      final fileName =
          'petji-backup-${DateTime.now().millisecondsSinceEpoch}.petji';
      final outputPath = p.join(directory.path, fileName);
      await _bundleService.exportBundle(
        snapshot: snapshot,
        outputPath: outputPath,
      );
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(outputPath)],
            text: '宠物记备份包',
            fileNameOverrides: [fileName],
          ),
        );
      } on Object {
        // The file is still available in app storage when share UI is unavailable.
      }
      if (mounted) {
        _showMessage('已生成.petji备份包');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('导出失败：$error');
      }
    }
  }

  Future<void> _pickImportBundle() async {
    const typeGroup = selector.XTypeGroup(
      label: 'Petji backup',
      extensions: ['petji', 'zip'],
    );
    final file = await selector.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }
    try {
      final preview = await _bundleService.importBundle(file.path);
      if (mounted) {
        _showImportPreview(file.path, preview);
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('无法识别.petji备份包：$error');
      }
    }
  }

  void _showImportPreview(String path, AppSnapshot preview) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入.petji包'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导入会作为新的宠物档案加入，不会替换当前本地数据。'),
              const SizedBox(height: 12),
              Text('宠物：${preview.pets.length}'),
              Text('成长线：${preview.timelineEvents.length}'),
              Text('待办：${preview.todos.length}'),
              Text('消费：${preview.expenses.length}'),
              const SizedBox(height: 12),
              Text(
                p.basename(path),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                try {
                  final root = await getApplicationDocumentsDirectory();
                  final imported = await _bundleService.importBundle(
                    path,
                    destinationDirectory: p.join(
                      root.path,
                      'petji',
                      'restored',
                    ),
                  );
                  ref
                      .read(appSnapshotProvider.notifier)
                      .importSnapshotAsPetProfiles(imported);
                  navigator.pop();
                  if (mounted) {
                    _showMessage('导入已完成');
                  }
                } on Object catch (error) {
                  navigator.pop();
                  if (mounted) {
                    _showMessage('导入失败：$error');
                  }
                }
              },
              child: const Text('确认导入'),
            ),
          ],
        );
      },
    );
  }

  Future<Directory> _backupDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'petji', 'backups'));
    await directory.create(recursive: true);
    return directory;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
