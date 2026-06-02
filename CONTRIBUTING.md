# 贡献指南 Contributing Guide

感谢你愿意为《宠物记》(PetJi) 做贡献。本项目是 Flutter 本地优先 App，首发 Android，同时预留 iOS、HarmonyOS 和后端云化扩展。贡献时请优先保持现有分层架构、数据隔离和移动端交互质量。

## 行为准则

- 尊重不同观点，讨论聚焦技术事实和用户价值。
- 反馈应具体、可执行，避免情绪化表达。
- 不提交侵犯版权、含水印或来源不明的图片、视频、字体和音频素材。
- 不在代码、日志、测试数据或截图里提交真实用户隐私数据。

## 贡献范围

欢迎提交：

- Flutter 页面、组件和交互优化。
- domain/application/data 分层内的业务能力。
- `.petji` 备份、导入导出、同步契约和本地存储改进。
- Android 权限、通知、文件选择、媒体导入等移动端体验。
- 单元测试、Widget 测试、集成验证脚本和文档。

当前 V1 不实现账号、云同步、商城、社区、AI 聊天和智能硬件控制。如果要做这些方向，请先开 Issue 讨论边界和接口契约。

## 项目结构

```text
lib/
  domain/        实体、枚举、Repository 接口和纯业务模型
  application/   用例、Provider、统计聚合、通知调度、备份包服务
  data/local/    Drift 数据库和本地快照存储
  presentation/  Flutter UI、ThemeData、页面和复用组件
docs/
  api-contract-v1.md  未来后端 REST JSON 契约
test/
  application/   业务逻辑和控制器测试
  data/          本地存储测试
  domain/        模型和序列化测试
  widgets/       页面交互和表单测试
```

请不要让页面层直接依赖 Drift 或文件系统实现。UI 应通过 Riverpod provider 调用 application 层能力；未来接入云端时，应能替换 repository / service 实现而不重写页面。

## 开发环境

请先确认本机已安装 Flutter、Dart、Android SDK、Android NDK 和可用的 Android 构建环境。安装依赖并生成代码：

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

如果遇到缺少 SDK、NDK、证书或插件环境的问题，请先修复环境，不要用手工生成文件绕过构建链。

## 分支与提交流程

1. Fork 仓库并克隆到本地。
2. 从 `main` 创建分支：
   ```powershell
   git checkout main
   git pull origin main
   git checkout -b feature/your-change
   ```
3. 小步提交，保持每个提交目标清晰。
4. 推送分支并发起 Pull Request。

建议分支命名：

- `feature/timeline-calendar`
- `fix/backup-import-path`
- `docs/contributing-guide`
- `test/expense-report`

## 提交信息

建议使用简洁的 Conventional Commits 风格：

- `feat: add pet profile edit form`
- `fix: keep shared expenses when deleting pet`
- `docs: update backup bundle instructions`
- `test: cover todo day deletion`
- `refactor: extract calendar grid widget`

中文提交也可以，但要保持动词清晰，例如 `feat: 首页疫苗卡显示绝育状态`。

## 编码规范

- 使用现有 Flutter / Riverpod / Drift 结构，不新增无必要的状态管理或数据库方案。
- 新功能先补测试，再写实现；Bug 修复应有回归测试。
- 结构化数据使用模型、序列化和 repository/service，不用临时字符串拼接替代。
- 金额统一使用 `amountCents` 整数，时间统一使用 `DateTime` 和 ISO-8601 JSON 字符串。
- 宠物相关数据必须按 `petId` 隔离；共享消费使用 `petId == null`。
- 文件附件只保存 App 管理目录内的路径或备份包内相对路径，避免直接依赖外部相册原始文件。
- UI 文案保持中文，表达短、准、可操作。

## UI/UX 要求

- 遵循项目设计方向：温暖实用、宠物科技感、圆润但不幼稚。
- 使用统一 `ThemeData`、颜色 token 和组件模式，不在页面散落硬编码视觉样式。
- 图标优先使用 Flutter Material Icons；不要用 emoji 充当功能图标。
- 关键按钮、表单、可点击卡片应提供 `Semantics` 或清晰 `tooltip`。
- 移动端优先检查 375px 宽度，避免文字溢出、卡片挤压和不可点击区域过小。
- 年/月/日视图应保持可递进、可返回、可理解，不只依赖颜色表达信息。

## AI 和图片资产

AI 生成资产只能用于非关键插画、空状态、引导图和 launcher icon 源图。提交生成资产时必须：

- 将文件放入 `assets/images/generated/`。
- 在 `assets/images/generated/README.md` 记录用途、模型、提示词摘要和后处理方式。
- 确保图片无水印、无版权风险、无真实个人隐私。
- 页面内功能图标仍优先使用 Flutter 图标库，避免风格不一致。

## 数据和备份包

`.petji` 是 zip 备份包，包含：

```text
manifest.json
snapshot.json
media/
files/
```

涉及导入导出时请重点验证：

- `snapshot.json` 的 `AppSnapshot.version` 和所有资源 ID。
- 附件路径是否解包并重写到 App 私有目录。
- 导入是否作为新宠物档案合并，不能覆盖当前数据。
- 原共享消费和待办是否按当前策略绑定到导入的第一只宠物。
- 非法 zip 路径、缺失 manifest、缺失 snapshot 的失败态。

## 测试要求

提交前至少运行：

```powershell
dart format --set-exit-if-changed lib test
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

根据改动范围补充测试：

- domain：模型、年龄、序列化、时间分组、媒体类型推断。
- application：controller、备份包、通知调度、消费汇总、导入合并。
- widgets：首页、成长线、待办、消费、我的页面关键交互。
- Android 真机或模拟器：通知权限、文件选择、媒体导入、数据库持久化、暗色/亮色模式。

## Pull Request 清单

PR 描述请包含：

- 改动摘要。
- 影响的页面、模型或服务。
- 测试命令和结果。
- 截图或录屏（UI 改动建议提供）。
- 已知限制或后续任务。

提交前自查：

- [ ] 没有默认宠物、默认消费或演示数据被重新加入 V1 启动流程。
- [ ] 多宠物数据隔离没有被破坏。
- [ ] 删除、导入、导出不会造成不可预期的数据丢失。
- [ ] 新增文件已纳入 `pubspec.yaml` 或相关 README 说明。
- [ ] 没有提交本机绝对路径、临时文件、构建产物或隐私数据。

## 许可证

通过向本仓库提交代码、文档或资产，你同意你的贡献在 [GPL-3.0](LICENSE) 许可证下发布。
