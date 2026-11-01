# WorkBuddy Windows 适配说明

## 项目来源

本项目是 [HeiGe Codex Skin Studio](https://github.com/HeiGeAi/heige-codex-skin-studio) 的独立、非官方衍生版本。上游 MIT 许可证允许复制、修改和分发代码，前提是保留原版权与许可文本；本仓库已遵守该条件。本项目没有沿用或伪造上游 Git 历史，也不会向上游仓库写入内容。

## 面向的客户端

适配目标是 Windows 国内版 WorkBuddy，已验证版本为 5.9.3，目标可执行文件为 `WorkBuddy.exe`。全球版 `WorkBuddyAI.exe` 不在目标列表中，也不应由脚本选择或终止。

## 与上游的主要差异

1. 新增 WorkBuddy 产品档案、进程身份识别与 Windows 安装目录解析。
2. 支持 WorkBuddy 的 `file://` 渲染页面，同时保持任意本地页面不可被控制。
3. 使用 WorkBuddy 自身读取的远程调试端口环境变量启动 CDP 会话。
4. 增加 WorkBuddy 专用应用、恢复、会话宿主与计划任务流程。
5. 增加 WorkBuddy 专用 CSS：背景图、透明顶栏、半透明侧边栏和高对比内容卡片。
6. 主题中心通过带能力令牌的页面请求与会话控制器通信，不开放宽泛的 `Origin: null` HTTP 控制通道。
7. 发布副本移除了上游第三方视觉素材、宣传截图、宠物资源、二维码及内部复盘材料，只保留自行生成的中性渐变主题。

## 运行流程

`workbuddy-apply.bat` 调用 PowerShell 入口，解析国内版安装路径并确认进程身份，随后以远程调试参数启动 WorkBuddy。Node.js 控制器连接指定页面，校验 URL、进程归属和会话能力后注入 CSS、主题数据与菜单。启用“皮肤常驻”后，当前用户计划任务会在登录及会话恢复时重新建立注入控制器。

恢复脚本会关闭本项目建立的控制会话、注销本项目任务，并以原生参数重新启动国内版 WorkBuddy。它不修改 WorkBuddy 安装目录中的 `app.asar`。

## 兼容标识说明

部分源代码中的 `heige-*` DOM 属性、`HEIGE_*` 环境变量、函数名和状态协议字段是从上游继承的稳定内部标识。为避免破坏状态迁移、跨进程握手和已有安全契约，它们被保留为兼容协议名；这些内部标识不代表 HeiGeAi 对本衍生项目的认可、维护或背书。用户可见产品名、仓库名、发布地址和 WorkBuddy 任务名均使用 `WorkBuddy Skin Studio`。

## 主题资产边界

仓库只带 `themes/neutral-gradient`。其中 `hero.png` 是为本仓库用代码生成的抽象渐变图，不含第三方角色、商标、摄影作品或二维码。用户自行导入的图片不自动获得再分发权；向公开仓库提交主题前，应提供明确的原创声明或兼容许可证。

## 测试边界

- `npm test`：Node.js 单元、协议、产品身份和 Windows 安全契约测试。
- `npm run test:windows`：Windows PowerShell 目标解析与任务管理测试。
- `npm run test:windows:acl`：需要普通本机 NTFS 权限的精确 ACL/崩溃恢复验收；受控沙箱或企业 ACL 策略可能使其安全失败。
- 实机验收必须仅针对国内版 `WorkBuddy.exe`，并在操作前退出客户端、保存会话。

本项目从不要求或触发 Windows Update、BIOS 更新或固件更新。

