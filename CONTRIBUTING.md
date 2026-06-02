# 贡献指南 Contributing Guide

感谢你考虑为《宠物记》(PetJi) 做出贡献！本指南将帮助你快速参与到项目中来。

> 说明：由于参考来源当前无法直接访问，本贡献指南基于 Flutter / Dart 开源社区的最佳实践编制。

## 行为准则

我们期望所有参与者保持友好、尊重与建设性。请遵守以下基本原则：

- 尊重不同的观点与经验。
- 接受建设性的批评。
- 关注对社区最有利的事情。
- 对其他社区成员表示同理心。

## 如何参与

### 报告问题 (Issues)

在提交 Issue 之前，请先搜索是否已有相似问题。

报告 Bug 时，请尽量包含以下信息：

- 问题摘要和清晰的重现步骤。
- 期望行为与实际行为。
- 运行环境（Flutter 版本、Dart 版本、操作系统及版本）。
- 相关的错误日志或屏幕截图。
- 最小可复现代码（如适用）。

### 提交功能建议

欢迎提交新功能建议！请在 Issue 中描述：

- 功能的用例与目标。
- 可能的实现方案（如果你已有思路）。
- 是否愿意自己实现该功能。

## 开发环境

本项目使用 Flutter 开发。请确保你的环境满足以下要求：

- Flutter SDK: `^3.12.0`
- Dart SDK: 随 Flutter 一起安装
- 支持的平台: Android、iOS（后续扩展 HarmonyOS）

安装依赖并生成代码：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 代码规范

我们使用 `flutter_lints` 和 `analysis_options.yaml` 来保持代码风格一致。

在提交代码前，请确保：

```bash
flutter analyze
```

无任何警告或错误。

## 测试

所有新功能和 Bug 修复都应尽可能附带测试。运行测试：

```bash
flutter test
```

请确保所有测试在提交前通过。

## 提交 Pull Request

1. **Fork** 本仓库到你的账号下。
2. **克隆** 你的 Fork 到本地：
   ```bash
   git clone https://github.com/<你的用户名>/PetJiApp.git
   ```
3. **创建功能分支**：
   ```bash
   git checkout -b feature/你的功能名称
   ```
   或修复分支：
   ```bash
   git checkout -b fix/问题简述
   ```
4. **编写代码**并确保通过分析与测试。
5. **提交更改**：
   ```bash
   git add .
   git commit -m "类型: 简短的描述"
   ```
6. **推送到你的 Fork**：
   ```bash
   git push origin feature/你的功能名称
   ```
7. 在原始仓库发起 **Pull Request**，并描述清楚改动内容。

## 提交信息规范 (Commit Message)

建议使用清晰的提交信息，例如：

- `feat: 添加消费报告按月筛选功能`
- `fix: 修复待办事项逾期计算错误`
- `docs: 更新 README 中的打包说明`
- `test: 补充 .petji 导入合并的边界测试`
- `refactor: 优化时间线数据分组逻辑`

## 代码审查

维护者会在可能的情况下尽快审查你的 Pull Request。请耐心等待，并根据反馈进行修改。

## 许可证

通过向本仓库提交代码，你同意你的贡献将在 [GPL-3.0](LICENSE) 许可证下发布。
