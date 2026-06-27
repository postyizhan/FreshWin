# FreshWin

FreshWin 是一个 Windows 初始化工具，通过交互式菜单快速配置新安装的 Windows 系统。使用 PowerShell 5.1+ 编写。

## 功能

- 任务栏设置
  - 清空任务栏固定图标
  - 关闭虚拟桌面切换按钮
  - 桌面添加“此电脑”图标
- 软件管理
  - winget 换中国源（USTC）
  - 删除 OneDrive
  - 禁用 Copilot 自启动
- 系统功能
  - 开启文件扩展名
  - 显示隐藏文件
  - 开启 WSL/WSL2 组件
  - 开启 Hyper-V
  - 设置 12 小时制时间格式
  - PowerShell 执行策略设为 RemoteSigned
  - 关闭右键菜单动画
  - 开启长路径支持
  - 关闭快速启动（双系统下 Linux 可正常挂载 NTFS 分区）
  - 关闭开始菜单推荐项目
  - 关闭 Windows 智能应用控制
  - 配置 Windows Terminal 为默认终端
- 浏览器配置
  - Chrome / Edge 开启扩展开发者模式
  - Edge 主页精简
  - Edge 隐藏 Copilot 侧边栏

## 运行方式

```bat
Run.bat
```

或直接运行：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\FreshWin.ps1
```

FreshWin 会自动请求管理员权限，以确保系统级设置可以执行。

## 注意事项

- 本工具会修改注册表、启用 Windows 可选功能、卸载 OneDrive，并可能重启资源管理器。
- WSL、Hyper-V、长路径支持、Windows 智能应用控制等设置可能需要重启后生效。
- 关闭 Windows 智能应用控制后，通常只能通过重置或重装 Windows 才能重新开启。
- 修改 Chrome / Edge Preferences 前，会自动在同目录创建一次 `.freshwin.bak` 备份。

## 项目结构

```text
FreshWin.ps1          # 入口、自动提权、菜单、Invoke-All
Run.bat               # 启动器，优先使用 Windows Terminal
utils/
  Common.ps1          # 公共工具函数
modules/
  Taskbar.ps1         # 任务栏设置
  Software.ps1        # 软件管理
  System.ps1          # 系统功能
  Browser.ps1         # 浏览器配置
```
