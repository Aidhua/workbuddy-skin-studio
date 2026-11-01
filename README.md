# WorkBuddy Skin Studio

Windows WorkBuddy 皮肤适配工具，基于 [HeiGe Codex Skin Studio](https://github.com/HeiGeAi/heige-codex-skin-studio) 的 MIT 许可代码改造。

> **非官方衍生项目。** 本项目与 WorkBuddy 官方团队、OpenAI、HeiGeAi 均无隶属、合作、背书或认可关系。“WorkBuddy”仅用于说明兼容目标。上游项目的原始版权与 MIT 许可证已完整保留。

## 适用范围

- Windows 国内版传统安装包 `WorkBuddy.exe`
- 已实机适配的客户端版本：WorkBuddy 5.9.3
- Node.js 22 或更高版本
- **不适用于**全球版 `WorkBuddyAI.exe`

本项目不修改 `app.asar`，不替换客户端二进制文件，不涉及 Windows Update、BIOS 或固件更新。它通过本机 CDP 会话向 WorkBuddy 渲染页面注入 CSS 和主题菜单。

## 快速使用

1. 完全退出国内版 WorkBuddy。
2. 双击 `scripts\windows\workbuddy-apply.bat`。
3. 等待 WorkBuddy 重新启动；顶部会出现“主题”入口。
4. 需要回到原生界面时，双击 `scripts\windows\workbuddy-restore.bat`。

默认仅捆绑项目自行生成的中性渐变背景，不包含动漫、游戏角色、二维码、宠物、宣传截图或来源不明的视觉素材。你可以在本机自行添加有权使用的主题资源，但请勿把无授权素材再次分发。

## 功能

- 背景图与半透明内容层
- 顶部透明、侧边栏高对比半透明效果
- 页面内主题入口与可读性增强
- “皮肤常驻”开关：按当前用户注册/注销会话任务
- 一键恢复 WorkBuddy 原生界面
- WorkBuddy 与 WorkBuddy AI 的进程身份隔离

## 安全边界

- 只允许目标为 `WorkBuddy.exe`、目录名为 `WorkBuddy` 的国内版身份链。
- 不把任意 `file://` 页面视为可信目标；控制消息需要会话能力令牌。
- 常驻任务为当前用户范围，不请求管理员权限。
- 项目不会自动下载主题，也不会收集或上传用户数据。

## 测试

```powershell
npm test
npm run test:windows
# 需要能精确修改 NTFS ACL 的普通本机终端；部分沙箱/企业策略环境会安全失败
npm run test:windows:acl
```

Windows 测试会验证目标解析、参数传递、计划任务边界以及 PowerShell 安全契约。ACL 验收要求测试目录允许当前用户移除继承并写入精确 ACL；受控沙箱若阻止这一点，测试会按设计安全失败。测试不应启动 Windows 更新、BIOS 更新或固件更新。

## 已知限制

- WorkBuddy 更新后 DOM 结构可能改变，需要重新适配选择器。
- 当前仅声明对 Windows 国内版 WorkBuddy 5.9.3 的实机兼容性。
- 深色/浅色由 WorkBuddy 自身外观设置手动切换，本项目不强制替你切换。
- 使用前应先保存工作并退出 WorkBuddy；运行中的会话会被正常关闭并重启。

技术差异、继承关系和兼容标识见 [WORKBUDDY_ADAPTATION.md](WORKBUDDY_ADAPTATION.md)。

## 许可证与归属

代码按 [MIT License](LICENSE) 发布。原作者版权声明保持不变；本仓库的 WorkBuddy 适配修改由 Aidhua 于 2026 年整理。更多归属与商标说明见 [NOTICE.md](NOTICE.md)。

