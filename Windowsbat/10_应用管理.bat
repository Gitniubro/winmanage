@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 应用管理
:: 一键卸载 Windows 预装应用（使用 winget）、
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
set "title=Windows管理小工具 - 应用管理"
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
call :app_setting
exit /b

:app_setting
call :reset_color_size
call :print_title "应用管理"
set "a="
call :print_separator
echo				1. 一键卸载预装应用 &echo.
echo				2. 打开程序和功能 &echo.
echo				3. OneDrive安装/卸载 &echo.
echo				4. 微软拼音输入法设置 &echo.
echo				0. 返回(q) &echo.
call :print_separator
set /p a=请输入你的选择: 
if "%a%"=="1" (
	call :uninstall_preinstalled_apps
)else if "%a%"=="2" (
	start "" appwiz.cpl
)else if "%a%"=="3" (
	choice /c 123 /n /m "OneDrive应用? [1.卸载 2.安装 3.取消]: "
	set /a op=!errorlevel!
	if !op! == 1 call :uninstall_OneDrive
	if !op! == 2 call :install_OneDrive
	if !op! == 3 goto :app_setting
)else if "%a%"=="4" (
	call :microsoft_pinyin
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto app_setting


:check_winget
where winget >nul 2>&1
if errorlevel 1 (
	echo 未找到 winget 程序，此功能暂不可用，请先安装 winget。
	call :wait_keydown "https://apps.microsoft.com/store/detail/9NBLGGH4NNS1"
	exit /b 1
)
exit /b 0

::卸载预装应用

:uninstall_preinstalled_apps
call :check_winget
if errorlevel 1 exit /b
echo	预装的应用包括：
echo		Microsoft 365 Copilot
echo		Microsoft Clipchamp
echo		Microsoft To Do
echo		Microsoft 必应
echo		Microsoft 资讯
echo		Game Bar
echo		Solitaire ^& Casual Games
echo		Xbox、Xbox TCUI、Xbox Identity Provider
echo		反馈中心
echo		Power Automate
echo		资讯
echo		Outlook for Windows
echo		小组件
echo.
call :ask_confirm "是否进行卸载? [Y/n]? " y
if errorlevel 1 exit /b
echo 正在卸载Microsoft 365 Copilot
winget uninstall "Microsoft 365 Copilot" --accept-source-agreements
echo 正在卸载Microsoft Clipchamp
winget uninstall "Microsoft Clipchamp"
echo 正在卸载Microsoft To Do
winget uninstall "Microsoft To Do"
echo 正在卸载Microsoft 必应 
winget uninstall "Microsoft 必应"
echo 正在卸载Microsoft 资讯 
winget uninstall "Microsoft 资讯"
echo 正在卸载Game Bar
winget uninstall "Game Bar"
echo 正在卸载Solitaire ^& Casual Games
winget uninstall "Solitaire & Casual Games"
echo 正在卸载Xbox
winget uninstall "Xbox"
echo 正在卸载Xbox TCUI
winget uninstall "Xbox TCUI"
echo 正在卸载Xbox Identity Provider
winget uninstall "Xbox Identity Provider"
echo 正在卸载反馈中心
winget uninstall "反馈中心"
echo 正在卸载资讯
winget uninstall "资讯"
echo 正在卸载Power Automate
winget uninstall "Power Automate"
echo 正在卸载Outlook for Windows
winget uninstall "Outlook for Windows"
call :widgets_uninstall
echo 卸载预装应用完成 & timeout /t 4
exit /b

:: 卸载OneDrive

:uninstall_OneDrive
echo 正在卸载 OneDrive...
taskkill /f /im OneDrive.exe >nul 2>&1
if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
	"%SystemRoot%\System32\OneDriveSetup.exe" /uninstall
) else if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
	"%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall
)
timeout /t 5 /nobreak >nul
rd /s /q "%UserProfile%\OneDrive" >nul 2>&1
rd /s /q "%LocalAppData%\Microsoft\OneDrive" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft OneDrive" >nul 2>&1
rd /s /q "%SystemDrive%\OneDriveTemp" >nul 2>&1
reg delete "HKCR\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1
reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1
call :sleep "卸载 OneDrive...OK" 5
exit /b

:: 安装OneDrive

:install_OneDrive
echo 正在安装 OneDrive...
if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
	"%SystemRoot%\System32\OneDriveSetup.exe"
) else if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
	"%SystemRoot%\SysWOW64\OneDriveSetup.exe"
) else (
	call :sleep "找不到 OneDrive 安装程序，请手动下载安装！" 4 silent
	start "" https://www.microsoft.com/zh-cn/microsoft-365/onedrive/download
)
call :sleep "已经完成" 5
exit /b

:: 微软拼音输入法设置 

:microsoft_pinyin
call :print_title "微软拼音输入法设置"
set "d="
call :print_separator
echo				1. 双拼输入 &echo.
echo				2. 全拼输入 &echo.
echo				3. 打开微软拼音设置 &echo.
echo				0. 返回(q) &echo.
call :print_separator "~"
echo  该设置仅用于【微软拼音输入法】，其他输入法请勿使用。 
call :print_separator
echo.
set /p "d=请输入你的选择: "
if "%d%"=="1" (
	echo.&echo		可选双拼方案： 
	echo				1. 软微双拼 
	echo				2. 智能ABC 
	echo				3. 自然码 
	choice /c 123 /n /m "请输入双拼方案: " 
	set /a sp_option=!errorlevel!
	if !sp_option! == 1 set "sp_code=0"
	if !sp_option! == 2 set "sp_code=1"
	if !sp_option! == 3 set "sp_code=3"
	call :microsoft_pinyin_select 1
	call :microsoft_pinyin_sp !sp_code!
	call :sleep "已设置双拼输入法" 6
)else if "%d%"=="2" (
	call :microsoft_pinyin_select 0
	call :sleep "已设置全拼输入法" 6
)else if "%d%"=="3" (
	start ms-settings:regionlanguage-chsime-pinyin
)
if "%d%"=="0" endlocal & exit /b
if /i "%d%"=="q" endlocal & exit /b
goto :microsoft_pinyin

:: 双拼输入法 0软微双拼 1智能ABC 3自然码 

:microsoft_pinyin_sp
reg add "HKCU\Software\Microsoft\InputMethod\Settings\CHS" /v DoublePinyinScheme /t REG_DWORD /d %~1 /f >nul 2>&1
exit /b

:: 输入法 1双拼 0全拼

:microsoft_pinyin_select
reg add "HKCU\Software\Microsoft\InputMethod\Settings\CHS" /v "Enable Double Pinyin" /t REG_DWORD /d %~1 /f >nul 2>&1
exit /b

:: 编辑hosts 

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