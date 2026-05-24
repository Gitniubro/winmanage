@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 任务栏设置
:: 一键净化任务栏、禁用/启用/卸载/安装小组件、
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
set "title=Windows管理小工具 - 任务栏设置"
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
call :taskbar
exit /b

:taskbar 
call :reset_color_size
call :print_title "任务栏设置"
set "a=" 
call :print_separator
echo			1. 一键净化任务栏                     11. 自动隐藏任务栏 — 开启 &echo.
echo			2. 禁用小组件                         12. 自动隐藏任务栏 — 关闭 &echo.
echo			3. 启用小组件                         13. 时间显示秒 &echo.
echo			4. 卸载小组件                         14. 时间隐藏秒（默认） &echo.
echo			5. 安装小组件 &echo.
echo			6. 任务视图 — 隐藏 &echo.
echo			7. 任务视图 — 显示 &echo.
echo			8. 搜索 - 隐藏 &echo.
echo			9. 搜索 - 仅显示搜索图标 &echo.
echo			10. 清除固定（Edge、商店、资源管理器） &echo.
echo			0. 返回(q) &echo.
call :print_separator
set /p a=请输入你的选择: 
if "%a%"=="1" (
	call :hide_taskview
	call :hide_search
	call :taskbar_unpin
	call :widgets_uninstall
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="2" (
	call :widgets_disable
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="3" (
	call :widgets_enable
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="4" (
	call :widgets_uninstall
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="5" (
	call :widgets_install
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="6" (
	call :hide_taskview
	call :sleep "操作完成！" 2
) else if "%a%"=="7" (
	call :show_taskview
    call :sleep "操作完成！" 2
) else if "%a%"=="8" (
	call :hide_search
    call :sleep "操作完成！" 2
) else if "%a%"=="9" (
	call :search_icon
    call :sleep "操作完成！" 2
) else if "%a%"=="10" (
	call :taskbar_unpin
	call :restart_explorer
    echo 操作完成！& timeout /t 2
) else if "%a%"=="11" (
	call :taskbar_auto_hide_on
    call :sleep "操作完成！" 2
) else if "%a%"=="12" (
	call :taskbar_auto_hide_off
    call :sleep "操作完成！" 2
) else if "%a%"=="13" (
	call :taskbar_time_second 1
	call :sleep "操作完成！" 2
) else if "%a%"=="14" (
	call :taskbar_time_second 0
	call :sleep "操作完成！" 2
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto taskbar


:widgets_disable
echo 正在禁用小组件...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1
sc config Widgets start= disabled >nul
sc stop Widgets >nul
sc config WebExperience start= disabled >nul
sc stop WebExperience >nul
echo 禁用小组件小组件...OK
exit /b


:widgets_enable
echo 正在启用小组件...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f >nul 2>&1
sc config Widgets start= demand >nul
sc config WebExperience start= demand >nul
sc start WebExperience >nul
echo 启用小组件...OK
exit /b


:widgets_uninstall
echo 正在卸载小组件...
winget uninstall "Windows Web Experience Pack" --accept-source-agreements
echo 卸载小组件...OK
exit /b


:widgets_install
echo 正在安装小组件...
winget install 9MSSGKG348SP --accept-package-agreements --accept-source-agreements
echo 安装小组件...OK
exit /b


:hide_taskview
echo 正在隐藏任务视图...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul 2>&1
echo 隐藏任务视图...OK
exit /b


:show_taskview
echo 正在显示任务视图...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 1 /f >nul 2>&1
echo 显示任务视图...OK
exit /b


:hide_search
echo 正在隐藏搜索...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul 2>&1
echo 正在隐藏搜索...OK
exit /b

:search_icon
echo 正在设置搜索图标... 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f >nul 2>&1
echo 设置搜索图标...OK 
exit /b


:search_icon
echo 正在设置搜索图标... 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f >nul 2>&1
echo 设置搜索图标...OK 
exit /b


:taskbar_unpin
echo 正在清除任务栏固定项目... 
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" >nul 2>&1
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband /f >nul 2>&1
echo 正在清除任务栏固定项目...OK 
exit /b


:taskbar_auto_hide_on
echo 开启任务栏自动隐藏... 
powershell -Command "&{$p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'; $v=(Get-ItemProperty -Path $p).Settings; $v[8]=3; Set-ItemProperty -Path $p -Name Settings -Value $v; Stop-Process -Name explorer -Force}"
exit /b


:taskbar_auto_hide_off
echo 关闭任务栏自动隐藏... 
powershell -Command "&{$p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'; $v=(Get-ItemProperty -Path $p).Settings; $v[8]=2; Set-ItemProperty -Path $p -Name Settings -Value $v; Stop-Process -Name explorer -Force}"
exit /b

::任务栏时间显示秒 0:隐藏 1:显示

:taskbar_time_second
set value=%~1
if "%value%"=="1" (
    echo 设置任务栏时间显示秒 
) else if "%value%"=="0" (
    echo 设置任务栏时间隐藏秒 
)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSecondsInSystemClock" /t REG_DWORD /d %value% /f >nul 2>&1
exit /b

:: 资源管理器设置 

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