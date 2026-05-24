@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 资源管理器设置
:: 默认打开此电脑/主文件夹、文件扩展名开关、
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
set "title=Windows管理小工具 - 资源管理器设置"
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
call :explorer_setting
exit /b

:explorer_setting
call :print_title "资源管理器设置"
set "a=" 
call :print_separator
echo			 1. 默认打开[此电脑/主文件夹]         11. 清理图标/缩略图缓存 &echo.
echo			 2. 文件扩展(后缀)名开关 &echo.
echo			 3. [单击/双击]打开文件 &echo.
echo			 4. [显示/隐藏]复选框 &echo.
echo			 5. [显示/隐藏]系统隐藏文件 &echo.
echo			 6. U盘禁用开关 &echo.
echo			 7. 导航栏-主文件夹开关 &echo.
echo			 8. 导航栏-图库开关 &echo.
echo			 9. 导航栏-控制面板开关 &echo.
echo			10. 导航栏-重复驱动器开关 &echo.
echo			 0. 返回(q) &echo.
call :print_separator
set /p "a=请输入你的选择:"
if "%a%"=="1" (
	echo 正在执行默认打开此电脑主文件夹设置...
	choice /c 12 /n /m "请选择你的操作? [1.主文件夹(系统默认) 2.此电脑]:"
	if errorlevel 2 (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f >nul 2>&1
		call :sleep "已设置默认打开此电脑！" 5
	) else (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 0 /f >nul 2>&1
		call :sleep "已设置默认打开主文件夹！" 5
	)
) else if "%a%"=="2" (
	echo.&echo 文件扩展（后缀）名设置 
	choice /c 12 /n /m "请选择你的操作? [1.显示 2.隐藏（系统默认）]: "
	if errorlevel 2 (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已隐藏扩展名" 6
	) else (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已显示扩展名" 6
	)
) else if "%a%"=="3" (
	echo.&echo [单击/双击]打开文件设置 
	choice /c 12 /n /m "请选择你的操作? [1.单击 2.双击（系统默认）]: "
	if errorlevel 2 (
		reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V ShellState /T REG_BINARY /D 240000003ea8000000000000000000000000000001000000130000000000000062000000 /F >nul 2>&1
		call :restart_explorer
		call :sleep "已设置双击打开文件！" 3
	) else (
		reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V IconUnderline /T REG_DWORD /D 2 /F >nul 2>&1
		reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V ShellState /T REG_BINARY /D 240000001ea8000000000000000000000000000001000000130000000000000062000000 /F >nul 2>&1
		call :restart_explorer
		call :sleep "已设置单击打开文件！" 3
	)
) else if "%a%"=="4" (
	echo.&echo [显示/隐藏]复选框 
	choice /c 12 /n /m "请选择你的操作? [1.显示 2.隐藏（系统默认）]: "
	if errorlevel 2 (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "AutoCheckSelect" /t REG_DWORD /d 0 /f >nul 2>&1
		call :sleep "已隐藏复选框，手动刷新生效" 6
	) else (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "AutoCheckSelect" /t REG_DWORD /d 1 /f >nul 2>&1
		call :sleep "已显示复选框，手动刷新生效" 6
	)
) else if "%a%"=="5" (
	echo.&echo [显示/隐藏]系统隐藏文件 
	choice /c 12 /n /m "请选择你的操作? [1.显示 2.隐藏（系统默认）]: "
	if errorlevel 2 (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f >nul 2>&1
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 0 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已隐藏系统隐藏文件，正在重启资源管理器" 6
	) else (
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul 2>&1
		reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 1 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已显示系统隐藏文件，正在重启资源管理器" 6
	)
) else if "%a%"=="6" (
	echo.echo 开启或禁用插入U盘 
	choice /c 12 /n /m "请选择你的操作? [1.启用（系统默认） 2.禁用]:"
	if errorlevel 2 (
		reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
		call :sleep "已禁用U盘使用" 6
	) else (
		reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
		call :sleep "已启用U盘使用" 6
	)
) else if "%a%"=="7" (
	call :explorer_home_folder_toggle
) else if "%a%"=="8" (
	call :explorer_gallery_toggle
) else if "%a%"=="9" (
	choice /c 12 /n /m "控制面板设置? [1.隐藏（系统默认） 2.显示]: "
	if errorlevel 2 (
		reg add "HKCU\Software\Classes\CLSID\{26EE0668-A00A-44D7-9371-BEB064C98683}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已显示控制面板" 6
	) else (
		reg add "HKCU\Software\Classes\CLSID\{26EE0668-A00A-44D7-9371-BEB064C98683}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1
		call :restart_explorer
		call :sleep "已隐藏控制面板" 6
	)
) else if "%a%"=="10" (
	choice /c 12 /n /m "重复驱动器? [1.删除 2.显示]: "
	if errorlevel 2 (
		reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" /v "" /t REG_SZ /d "Removable Drives" /f
		call :sleep "已显示重复驱动器" 6
	) else (
		reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" /f
		call :sleep "已删除重复驱动器" 6
	)
)  else if "%a%"=="11" (
	call :clear_icon_cache
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto :explorer_setting

:: 资源管理器-导航栏-主文件夹 

:explorer_home_folder_toggle
set "HOME_FOLDER_TOGGLE_REG=tmp.reg"
choice /c 123 /n /m "主文件夹设置? [1.隐藏 2.显示 3.返回]: "
if "%errorlevel%"=="3" exit /b
if "%errorlevel%"=="1" (set "v=0" & set "op_name=隐藏") else (set "v=1" & set "op_name=显示")
(
	echo Windows Registry Editor Version 5.00
	echo.
	echo [HKEY_CURRENT_USER\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}]
	echo "System.IsPinnedToNameSpaceTree"=dword:0000000%v%
) > "%HOME_FOLDER_TOGGLE_REG%"
regedit.exe /s "%HOME_FOLDER_TOGGLE_REG%"
IF EXIST "%HOME_FOLDER_TOGGLE_REG%" DEL "%HOME_FOLDER_TOGGLE_REG%"
call :sleep "已设置主文件夹 %op_name% ，请重新打开资源管理器查看效果" 10
exit /b

:: 资源管理器设置-导航栏-图库 

:explorer_gallery_toggle
set "GALLERY_TOGGLE_REG=tmp.reg"
choice /c 123 /n /m "图库设置? [1.隐藏 2.显示 3.返回]: "
if "%errorlevel%"=="3" exit /b
if "%errorlevel%"=="1" (set "v=0" & set "op_name=隐藏") else (set "v=1" & set "op_name=显示")
(
	echo Windows Registry Editor Version 5.00
	echo.
	echo [HKEY_CURRENT_USER\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}]
	echo "System.IsPinnedToNameSpaceTree"=dword:0000000%v%
) > "%GALLERY_TOGGLE_REG%"
regedit.exe /s "%GALLERY_TOGGLE_REG%"
IF EXIST "%GALLERY_TOGGLE_REG%" DEL "%GALLERY_TOGGLE_REG%"
call :sleep "已设置图库 %op_name% ，请重新打开资源管理器查看效果" 10
exit /b


:: 清理图标/缩略图缓存 

:clear_icon_cache
taskkill /f /im explorer.exe >nul 2>&1
echo 正在删除图标缓存...
del /f /s /q "%localappdata%\IconCache.db" >nul 2>&1
del /f /s /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
echo 正在清理缩略图缓存...
del /f /s /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
call :restart_explorer
call :sleep "清理完成" 6
exit /b

:: 下载 Windows

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