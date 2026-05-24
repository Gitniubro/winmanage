@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 右键菜单设置
:: 切换 Windows 10/11 右键菜单样式、添加/删除超级菜单、
:: ============================================================

:: 使用管理员权限运行
net session >nul 2>&1 || (powershell -NoP -C "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', '""%~f0" %*"' -Verb RunAs" && exit)

:: 初始化配置参数
call :init_parameters
:: 接收传参来直接调用特定的子程序
if "%~1" neq "" (call :%~1) else (call :main_menu) & exit /b

:: 初始化配置参数
:init_parameters
set "color=0A"
set "title=Windows管理小工具 - 右键菜单设置"
set "updated=20260509"
set "rversion=v1.0.0"
set "cols=100"
set "lines=40"
set "separator=="
:: 存放设置
set "CONF_DIR=%APPDATA%\Windowsbat"
set "CONF_FILE=%CONF_DIR%\config.cmd"
call :load_config
call :reset_color_size
title %title%
exit /b


:main_menu
call :submenu_right_click
exit /b

:submenu_right_click
call :print_title "右键菜单设置"
set "a="
call :print_separator
echo				1. 切换 Windows 10 右键菜单 & echo.
echo				2. 恢复 Windows 11 右键菜单 & echo.
echo				3. 添加超级菜单 & echo.
echo				4. 删除超级菜单 & echo.
echo				5. 添加Hash右键菜单 & echo.
echo				6. 删除Hash右键菜单 & echo.
echo				0. 返回(q)  & echo.
call :print_separator
set /p a=请输入你的选择: 
if "%a%"=="1" ( 
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1
    call :restart_explorer
) else if "%a%"=="2" ( 
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f  >nul 2>&1
    call :restart_explorer
) else if "%a%"=="3" (
	echo 添加超级菜单...
	call :delete_SuperMenu
	call :add_SuperMenu
	call :sleep "添加超级菜单成功!" 5
) else if "%a%"=="4" ( 
	echo 删除超级菜单...
	call :delete_SuperMenu
	call :sleep "超级菜单已删除" 5
) else if "%a%"=="5" ( 
	reg add "HKCR\*\shell\GetFileHash" /v "MUIVerb" /t REG_SZ /d "Hash" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash" /v "Icon" /t REG_SZ /d "shell32.dll,-42" /f>nul 2>&1 
	reg add "HKCR\*\shell\GetFileHash" /v "SubCommands" /t REG_SZ /d "" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\01SHA1" /v "MUIVerb" /t REG_SZ /d "SHA1" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\01SHA1\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm SHA1 ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\02SHA256" /v "MUIVerb" /t REG_SZ /d "SHA256" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\02SHA256\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm SHA256 ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\03SHA384" /v "MUIVerb" /t REG_SZ /d "SHA384" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\03SHA384\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm SHA384 ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\04SHA512" /v "MUIVerb" /t REG_SZ /d "SHA512" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\04SHA512\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm SHA512 ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\05MACTripleDES" /v "MUIVerb" /t REG_SZ /d "MACTripleDES" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\05MACTripleDES\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm MACTripleDES ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\06MD5" /v "MUIVerb" /t REG_SZ /d "MD5" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\06MD5\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm MD5 ^| format-list\"" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\07RIPEMD160" /v "MUIVerb" /t REG_SZ /d "RIPEMD160" /f >nul 2>&1
	reg add "HKCR\*\shell\GetFileHash\shell\07RIPEMD160\command" /ve /t REG_SZ /d "powershell -noexit -command \"get-filehash -literalpath '%%1' -algorithm RIPEMD160 ^| format-list\"" /f >nul 2>&1
	call :sleep "添加Hash右键菜单完成!" 3
)  else if "%a%"=="6" ( 
	echo 正在删除Hash右键菜单...
	reg delete "HKCR\*\shell\GetFileHash" /f >nul 2>&1
	call :sleep "Hash右键菜单已删除!" 3
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto submenu_right_click

:: 添加超级菜单，后面看看怎么使用reg文件进行处理

:add_SuperMenu
	reg add "HKCR\*\shell\SuperMenu" /f /v "Icon" /t REG_SZ /d "shell32.dll,-16748">nul 2>&1 
	reg add "HKCR\*\shell\SuperMenu" /f /v "MUIVerb" /t REG_SZ /d "超级菜单(&X)">nul 2>&1 
	reg add "HKCR\*\shell\SuperMenu" /f /v "SeparatorAfter" /t REG_SZ /d "1">nul 2>&1 
	reg add "HKCR\*\shell\SuperMenu" /f /v "SubCommands" /t REG_SZ /d "X.CopyPath;X.CopyName;X.CopyTo;X.MoveTo;X.Attributes;X.GetHash;X.Notepad;X.Runas;X.PermanentDelete;Windows.RecycleBin.Empty">nul 2>&1 
	reg add "HKCR\DesktopBackground\Shell\SuperMenu" /f /v "Icon" /t REG_SZ /d "shell32.dll,-16748">nul 2>&1 
	reg add "HKCR\DesktopBackground\Shell\SuperMenu" /f /v "MUIVerb" /t REG_SZ /d "超级菜单(&X)">nul 2>&1 
	reg add "HKCR\DesktopBackground\Shell\SuperMenu" /f /v "SeparatorAfter" /t REG_SZ /d "1">nul 2>&1 
	reg add "HKCR\DesktopBackground\Shell\SuperMenu" /f /v "SubCommands" /t REG_SZ /d "X.FolderOpt.Menu;X.Cmd;X.ACmd;X.Powershell;X.APowershell;X.System.Menu;Windows.RecycleBin.Empty">nul 2>&1 
	reg add "HKCR\DesktopBackground\Shell\SuperMenu" /f /v "Position" /t REG_SZ /d "Top">nul 2>&1 
	reg add "HKCR\Directory\background\shell\SuperMenu" /f /v "Icon" /t REG_SZ /d "shell32.dll,-16748">nul 2>&1 
	reg add "HKCR\Directory\background\shell\SuperMenu" /f /v "MUIVerb" /t REG_SZ /d "超级菜单(&X)">nul 2>&1 
	reg add "HKCR\Directory\background\shell\SuperMenu" /f /v "SeparatorAfter" /t REG_SZ /d "1">nul 2>&1 
	reg add "HKCR\Directory\background\shell\SuperMenu" /f /v "SubCommands" /t REG_SZ /d "X.FolderOpt.Menu;X.Cmd;X.ACmd;X.Powershell;X.APowershell;X.System.Menu;Windows.RecycleBin.Empty">nul 2>&1 
	reg add "HKCR\Directory\background\shell\SuperMenu" /f /v "Position" /t REG_SZ /d "Top">nul 2>&1 
	reg add "HKCR\Folder\shell\SuperMenu" /f /v "Icon" /t REG_SZ /d "shell32.dll,-16748">nul 2>&1 
	reg add "HKCR\Folder\shell\SuperMenu" /f /v "MUIVerb" /t REG_SZ /d "超级菜单(&X)">nul 2>&1 
	reg add "HKCR\Folder\shell\SuperMenu" /f /v "SeparatorAfter" /t REG_SZ /d "1">nul 2>&1 
	reg add "HKCR\Folder\shell\SuperMenu" /f /v "SubCommands" /t REG_SZ /d "X.CopyPath;X.CopyName;X.CopyTo;X.MoveTo;X.Attributes;X.Filenames;X.ListedFiles;X.Cmd;X.ACmd;X.RunasD;X.PermanentDelete;Windows.RecycleBin.Empty">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ACmd" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5324">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ACmd" /f /v "MUIVerb" /t REG_SZ /d "在此处打开命令窗口 (管理员)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ACmd\Command" /f /ve /t REG_SZ /d "PowerShell -NoProfile -Command \"Start-Process cmd.exe -ArgumentList '/s,/k,pushd,%%V' -Verb RunAs\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.APowershell" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5373">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.APowershell" /f /v "MUIVerb" /t REG_SZ /d "在此处打开Powershell (管理员)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.APowershell\Command" /f /ve /t REG_SZ /d "powershell.exe -NoProfile -Command \"Start-Process powershell.exe -ArgumentList '-NoExit','-Command','Set-Location -LiteralPath ''%%V''' -Verb RunAs\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5314">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes" /f /v "MUIVerb" /t REG_SZ /d "文件属性">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes" /f /v "SubCommands" /t REG_SZ /d "">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\01" /f /v "Icon" /t REG_SZ /d "imageres.dll,-9">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\01" /f /v "MUIVerb" /t REG_SZ /d "添加「系统、隐藏」">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\01\Command" /f /ve /t REG_SZ /d "attrib +s +h \"%%1\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\02" /f /v "Icon" /t REG_SZ /d "imageres.dll,-10">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\02" /f /v "MUIVerb" /t REG_SZ /d "移除「系统、隐藏、只读、存档」">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes\Shell\02\Command" /f /ve /t REG_SZ /d "attrib -s -h -r -a \"%%1\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Cmd" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5323">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Cmd" /f /v "MUIVerb" /t REG_SZ /d "在此处打开命令窗口">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Cmd\Command" /f /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyName" /f /v "Icon" /t REG_SZ /d "imageres.dll,-90">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyName" /f /v "MUIVerb" /t REG_SZ /d "复制名字">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyName\Command" /ve /t REG_SZ /d "powershell -NoProfile -Command \"Set-Clipboard ([IO.Path]::GetFileName('%%1'))\"" /f>nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyPath" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5302">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyPath" /f /v "MUIVerb" /t REG_SZ /d "复制路径">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyPath\Command" /f /ve /t REG_SZ /d "powershell -NoProfile -Command \"Set-Clipboard '%%1'\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyTo" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5304">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyTo" /f /v "MUIVerb" /t REG_SZ /d "复制到...(&C)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyTo" /f /v "ExplorerCommandHandler" /t REG_SZ /d "{AF65E2EA-3739-4e57-9C5F-7F43C949CE5E}">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Device" /f /v "Icon" /t REG_SZ /d "DeviceCenter.dll,-1">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Device" /f /v "MUIVerb" /t REG_SZ /d "设备和打印机">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Device\Command" /f /ve /t REG_SZ /d "explorer.exe shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditEnvVar" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5374">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditEnvVar" /f /v "MUIVerb" /t REG_SZ /d "环境变量">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditEnvVar\Command" /f /ve /t REG_SZ /d "rundll32.exe sysdm.cpl,EditEnvironmentVariables">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditHosts" /f /v "Icon" /t REG_SZ /d "imageres.dll,-114">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditHosts" /f /v "MUIVerb" /t REG_SZ /d "编辑Hosts">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditHosts\Command" /f /ve /t REG_SZ /d "powershell.exe -NoProfile -Command \"Start-Process 'notepad.exe' -ArgumentList 'C:\Windows\System32\drivers\etc\hosts' -Verb RunAs\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Filenames" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5306">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Filenames" /f /v "MUIVerb" /t REG_SZ /d "生成文件名单">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Filenames\Command" /f /ve /t REG_SZ /d "cmd.exe /c @echo off&(for %%%%i in (%%1\*) do echo %%%%~nxi)>\"%%1_Filenames.txt\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.FolderOpt.Menu" /f /v "Icon" /t REG_SZ /d "shell32.dll,-210">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.FolderOpt.Menu" /f /v "MUIVerb" /t REG_SZ /d "文件夹选项">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.FolderOpt.Menu" /f /v "SubCommands" /t REG_SZ /d "Windows.ShowHiddenFiles;Windows.ShowFileExtensions;Windows.folderoptions">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GetHash" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5340">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GetHash" /f /v "MUIVerb" /t REG_SZ /d "获取文件校验值 (Hash)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GetHash\Command" /ve /t REG_SZ /d "powershell.exe -NoProfile -NoExit -Command \"write-host '%%1' -ForegroundColor Green; 'MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512', 'RIPEMD160' ^| ForEach-Object { Get-FileHash '%%1' -Algorithm $_ ^| Select-Object Algorithm, Hash}\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GodMode" /f /v "Icon" /t REG_SZ /d "control.exe">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GodMode" /f /v "MUIVerb" /t REG_SZ /d "所有任务">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GodMode\Command" /f /ve /t REG_SZ /d "explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ListedFiles" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5350">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ListedFiles" /f /v "MUIVerb" /t REG_SZ /d "生成文件列表 (遍历目录)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ListedFiles\Command" /f /ve /t REG_SZ /d "cmd.exe /c @echo off&(for /f \"delims=\" %%%%i in ('dir /b /a-d /s \"%%1\"') do echo %%%%i)>\"%%1_ListedFiles.txt\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.MoveTo" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5303">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.MoveTo" /f /v "MUIVerb" /t REG_SZ /d "移动到...(&M)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.MoveTo" /f /v "ExplorerCommandHandler" /t REG_SZ /d "{A0202464-B4B4-4b85-9628-CCD46DF16942}">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Notepad" /f /v "Icon" /t REG_SZ /d "shell32.dll,-152">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Notepad" /f /v "MUIVerb" /t REG_SZ /d "使用记事本打开">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Notepad\Command" /f /ve /t REG_SZ /d "notepad.exe \"%%1\"">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.PermanentDelete" /f /v "CommandStateSync" /t REG_SZ /d "">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.PermanentDelete" /f /v "ExplorerCommandHandler" /t REG_SZ /d "{E9571AB2-AD92-4ec6-8924-4E5AD33790F5}">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.PermanentDelete" /f /v "Icon" /t REG_SZ /d "shell32.dll,-240">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Powershell" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5372">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Powershell" /f /v "MUIVerb" /t REG_SZ /d "在此处打开Powershell">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Powershell\Command" /f /ve /t REG_SZ /d "powershell.exe -noexit -command Set-Location -literalPath '%%V'">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RestartExplorer" /f /v "Icon" /t REG_SZ /d "shell32.dll,-16739">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RestartExplorer" /f /v "MUIVerb" /t REG_SZ /d "重启资源管理器">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RestartExplorer\Command" /f /ve /t REG_SZ /d "cmd.exe /c taskkill /f /im explorer.exe & start explorer.exe" >nul 2>&1
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Runas" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5356">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Runas" /f /v "MUIVerb" /t REG_SZ /d "管理员取得所有权">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Runas\Command" /f /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" && icacls \"%%1\" /grant administrators:F">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RunasD" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5356">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RunasD" /f /v "MUIVerb" /t REG_SZ /d "管理员取得所有权 (遍历目录)">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RunasD\Command" /f /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RunasD\Command" /f /v "IsolatedCommand" /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.System.Menu" /f /v "Icon" /t REG_SZ /d "imageres.dll,-5308">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.System.Menu" /f /v "MUIVerb" /t REG_SZ /d "系统命令">nul 2>&1 
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.System.Menu" /f /v "SubCommands" /t REG_SZ /d "X.GodMode;X.EditEnvVar;X.EditHosts;X.Device;X.RestartExplorer">nul 2>&1 
	exit /b 

:: 删除超级菜单

:delete_SuperMenu
	reg delete "HKCR\*\shell\SuperMenu" /f >nul 2>&1 
	reg delete "HKCR\DesktopBackground\Shell\SuperMenu" /f >nul 2>&1 
	reg delete "HKCR\Directory\background\shell\SuperMenu" /f >nul 2>&1 
	reg delete "HKCR\Folder\shell\SuperMenu" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ACmd" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.APowershell" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Attributes" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Cmd" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyName" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyPath" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.CopyTo" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Device" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditEnvVar" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.EditHosts" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Filenames" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.FolderOpt.Menu" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GetHash" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.GodMode" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.ListedFiles" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.MoveTo" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Notepad" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.PermanentDelete" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Powershell" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RestartExplorer" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.Runas" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.RunasD" /f >nul 2>&1 
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\X.System.Menu" /f >nul 2>&1 
	exit /b

:: 桌面设置

:print_separator
setlocal
set "char=%~1" 
if "%char%"=="" set "char=%separator%"
set "count=%~2"
if "%count%"=="" set "count=%cols%"
set "line="
for /L %%i in (1,1,%count%) do (set "line=!line!!char!")
echo !line!
echo.
endlocal & exit /b

:: 打印标题 
:: 参数1 = 文本内容 

:print_title 
setlocal & cls 
set "title=%~1"
set "count=%~2"
if "%count%"=="" (
    set "space_str=                                       " 
) else (
    set "space_str="
    for /L %%i in (1,1,%count%) do (set "space_str=!space_str! ")
)
echo.
echo !space_str!!title!
echo.
endlocal & exit /b

:: 重启资源管理器 

:restart_explorer
taskkill /f /im explorer.exe >nul 2>&1 & start explorer & exit /b

:: 读取注册表键值 
:: 参数1=注册表路径，参数2=值名称 
:: 返回值：ret_value 

:read_reg_value
set "ret_value="
set "reg_cmd=reg query "%~1" /v "%~2" 2^>nul ^| findstr /I /C:"%~2""
for /f "tokens=1,2,*" %%G in ('%reg_cmd%') do (
	set "ret_value=%%I"
)
exit /b

:: 询问选择 
:: 如果选了默认值，errorlevel是0，否则是1 
:: 参数1：提示信息 
:: 参数2：默认值 

:ask_confirm
setlocal
set "input="
set /p "input=%~1"
if not defined input set "input=%~2"
if /i "%input%"=="%~2" (endlocal & exit /b 0) else (endlocal & exit /b 1)

:: 等待后运行 
:: 参数1：提示信息(默认"请稍候...") 
:: 参数2：等待时间(默认1s) 
:: 参数3：可选silent，是否静默等待（默认显示倒计时） 

:sleep
setlocal
set "msg=%~1" & set "sec=%~2" & set "silent=%~3"
if not defined msg set "msg=请稍候..." 
if not defined sec set "sec=1"
if not "%msg%"=="" if not "%msg%"==" " echo %msg%
if /i "%silent%"=="silent" (
    timeout /t %sec% >nul
) else (
    timeout /t %sec%
)
endlocal & exit /b

:: 等待按键后继续 

:wait_keydown
if "%~1" neq "" (echo %~1 & pause >nul) else (echo 按任意键继续 & pause >nul)
exit /b

:: 重启系统 

:load_config
if exist "%CONF_FILE%" (
    call "%CONF_FILE%"
)
exit /b

:: 保存自定义的设置 

:save_config
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
(
echo set "color=%color%"
) > "%CONF_FILE%"
exit /b

:: 清空自定义的设置 

:clean_config
if exist "%CONF_DIR%" (
	rmdir /s /q "%CONF_DIR%"
)
call :init_parameters
exit /b

:: 设置颜色和窗口大小 

:reset_color_size
call :reset_color
call :reset_size
exit /b


:reset_color
color %color% &  exit /b


:reset_size
mode con cols=%cols% lines=%lines%
exit /b

:: 程序退出 

:byebye
call :sleep "byebye" 1 silent & exit