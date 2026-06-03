# 宠物记 Petji

《宠物记》是一个面向养宠用户的 Flutter App。V1 采用本地优先架构，首发 Android，同时保留 iOS、HarmonyOS、云同步、商城社区、AI 助手和智能硬件控制的扩展边界。

## 功能范围

- 首次建档：无宠物档案时进入登记页，填写宠物姓名、生日，可选物种、预设/自定义品种和头像。
- 多宠物档案：首页头像入口支持切换、新增和硬删除宠物档案；首页宠物大标签支持更换当前宠物头像。
- 首页概览：展示年龄、最新体重、疫苗次数/绝育状态、本月消费四个指标，并显示最多 5 条最近动态。
- 快捷记录：体重、喂食克数、疫苗/驱虫日期和可选凭证图、体检报告文件。
- 成长线：记录、照片、视频、疫苗、驱虫、体检报告等事件统一进入时间线，支持年图谱、月故事板和日详情；日详情支持删除。
- 待办：新增标题、内容、日期，勾选完成，按年/月/日递进查看完成率和逾期数；日详情支持删除。
- 消费报告：新增标题、金额、类别、日期，可选择当前宠物或全家共用，按年/月/日递进查看汇总和明细；日详情支持删除。
- 数据备份：导出 `.petji` 备份包，导入前预览并作为新的宠物档案合并进当前数据。

V1 不包含账号、后端服务、云同步、商城、社区、AI 聊天或智能硬件控制。

## 技术栈

- Flutter / Dart
- Riverpod：端侧状态和依赖注入
- Drift + SQLite：本地快照持久化
- fl_chart：消费统计图表
- image_picker：头像、凭证图片、照片/视频选择
- file_selector：体检报告文件和 `.petji` 文件选择
- archive：`.petji` zip 包生成和解析
- share_plus：调用系统分享导出备份包
- flutter_local_notifications：Android 本地通知调度入口

## 架构

```text
lib/
  domain/        实体、枚举、Repository 接口
  application/   业务用例、汇总逻辑、备份包、通知调度、Provider
  data/local/    Drift 数据库和本地快照存储
  presentation/  Flutter UI、ThemeData、页面和组件
docs/
  api-contract-v1.md  未来后端 REST JSON 契约
```

页面层只读取 application/provider 暴露的数据，不直接依赖 Drift。后续接入云端时，可以新增 `RemoteApiClient`、`SyncRepository` 和远端 Repository 实现，保持 UI 和 domain 接口稳定。

## 本地运行

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

## Android 打包

调试包：

```powershell
flutter build apk --debug
```

发布包：

```powershell
flutter build apk --release
```

普通安卓真机建议使用带 ARM Flutter 引擎的发布包：

```powershell
flutter build apk --release --target-platform android-arm,android-arm64
```

产物路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

如果安装后启动即闪退，并在日志中看到类似信息：

```text
Could not find 'libflutter.so'. Looked for: [arm64-v8a, armeabi-v7a, armeabi], but only found: [x86_64].
```

说明安装的 APK 只包含 x86_64 Flutter 引擎，适合 x86_64 模拟器，不适合普通 ARM 安卓手机。请重新执行上面的 `--target-platform android-arm,android-arm64` 发布包命令，并安装新的 `app-release.apk`。调试真机时也可以显式指定：

```powershell
flutter build apk --debug --target-platform android-arm64
```

正式发布前还需要配置 Android 签名、隐私政策、媒体权限说明、文件访问说明和通知权限说明。Android 调试图标已使用项目内生成资产替换。

## 数据模型

所有可同步资源都带有稳定 `id`、`createdAt`、`updatedAt`、`deletedAt`。金额使用 `amountCents` 整数，时间使用 ISO-8601 字符串。

核心实体：

- `PetProfile`
- `WeightRecord`
- `FeedingRecord`
- `CareRecord`
- `ReminderRule`
- `Reminder`
- `MediaAsset`
- `ExpenseEntry`
- `TodoItem`
- `TimelineEvent`
- `AppSnapshot` v2

未来后端契约见 [docs/api-contract-v1.md](docs/api-contract-v1.md)。

## .petji 备份包

`.petji` 是 zip 包，结构如下：

```text
manifest.json
snapshot.json
media/
files/
```

- `snapshot.json` 保存 v2 业务快照。
- `media/` 保存头像、成长照片/视频、疫苗/驱虫凭证图。
- `files/` 保存体检报告等文件。
- 导入时会解压附件到 App 私有目录，并将快照中的相对路径重写为本机路径。
- 当前导入策略是合并为新的宠物档案：导入时重写宠物和关联资源 ID，避免覆盖现有数据。
- 导入包内原本未绑定宠物的消费和待办会绑定到导入的第一只宠物，避免污染当前全家共用账目。

## UI/UX 设计

设计系统由 `$ui-ux-pro-max` 生成并保存在 [design-system/宠物记/MASTER.md](design-system/宠物记/MASTER.md)。

- 主色：`#F97316`
- CTA / 信任蓝：`#2563EB`
- 背景：`#FFF7ED`
- 风格：温暖实用、宠物科技感、圆润但不幼稚
- Flutter 实现：统一 `ThemeData`，关键表单和按钮添加 `Semantics`

## AI 图像资产

项目资产目录：[assets/images/generated](assets/images/generated)

当前包含 `empty_timeline.png` 和 `app_icon_petji.png`。前者用于成长线和首次空状态，后者作为 Android launcher icon 的源图。生成提示词和用途记录在 [assets/images/generated/README.md](assets/images/generated/README.md)。

原则：

- 插画、空状态、引导图可以使用 `gpt-image-2`。
- 页面内图标、按钮、导航和状态图标使用 Flutter 图标库，避免 AI 图标风格漂移；launcher icon 可使用生成资产，但需要进入仓库并记录提示词。
- 项目引用的生成资产必须复制进仓库资产目录，不能只留在本机生成缓存。

## 测试

已覆盖：

- 空快照首次建档
- 宠物年龄展示
- AppSnapshot v2、待办、成长事件 JSON 往返
- 提醒规则生成
- 月度消费聚合和分类汇总
- 成长线、待办、消费的时间分组
- 多宠物切换、硬删除级联、消费共享过滤和 `.petji` 合并导入
- `.petji` 包导出、manifest、附件打包
- Drift 本地快照存储
- 首页、成长线、待办、消费、我的关键 widget 交互

运行：

```powershell
flutter analyze
flutter test
```

## 后续路线

- 将 Drift 快照表扩展为资源级表，提升查询和同步效率。
- 将更多文件权限、通知权限和失败态做成用户可恢复流程。
- 接入账号与云同步，实现 `/api/v1/sync/batch`。
- 后续接入 AI 喂食建议和宠物行为解释时，加入免责声明和专业来源。
- 评估通用智能家居协议对喂食机、饮水机的控制能力。
