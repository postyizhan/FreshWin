# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

FreshWin 是一个 Windows 初始化工具，通过交互式菜单快速配置新安装的 Windows 系统。使用 PowerShell 5.1+ 编写。

## 运行方式

```bat
# 双击运行（推荐，自动绕过执行策略）
Run.bat

# 或直接运行 PowerShell
PowerShell -ExecutionPolicy Bypass -File FreshWin.ps1
```

FreshWin 会自动请求管理员权限：非管理员运行 `FreshWin.ps1` 时，会以管理员身份重启自身，以确保系统级设置可以执行。

## 架构

入口：`FreshWin.ps1` — 加载所有模块，提供交互式菜单主循环。

```
FreshWin.ps1          # 入口、自动提权、菜单、Invoke-All
utils/
  Common.ps1          # 公共工具函数（所有模块依赖）
modules/
  Taskbar.ps1         # 任务栏设置
  Software.ps1        # 软件管理
  System.ps1          # 系统功能
  Browser.ps1         # 浏览器配置
```

每个模块暴露一个 `Invoke-XxxAll` 函数，由主菜单或 `Invoke-All` 调用。

## 开发约定

**公共工具函数**（`utils/Common.ps1`）：
- `Write-Status 'OK'|'SKIP'|'FAIL' $Message` — 统一输出状态
- `Set-RegistryValue / Get-RegistryValue / Remove-RegistryValue` — 注册表操作封装
- `Test-Admin` — 检查是否以管理员运行
- `Invoke-Cmd` — 执行外部命令并捕获退出码
- `Restart-Explorer` — 重启资源管理器使设置生效

**新增功能模式**：每个操作函数应先检查当前状态，已满足则输出 `SKIP`，操作成功输出 `OK`，失败输出 `FAIL` 并附带错误信息。

**语言**：代码注释和用户界面文本均使用中文。
