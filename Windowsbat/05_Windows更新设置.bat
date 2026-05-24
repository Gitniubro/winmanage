@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: Windows 更新设置
:: 暂停 Windows 更新至 2999 年、恢复 Windows 更新
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
set "title=Windows管理小工具 - Windows更新设置"
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
call :windows_update
exit /b

:windows_update
call :print_title "Windows更新设置"
set "a="
call :print_separator
echo			1. 暂停更新至2999年 &echo.
echo			2. 恢复更新 &echo.
echo			0. 返回(q) &echo.
call :print_separator
echo.
set /p a=请输入你的选择: 
set "UPDATE_REG=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
if "%a%"=="1" (
	echo 正在暂停更新...
	reg add "%UPDATE_REG%" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d 7152 /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "2024-01-01T10:00:52Z" /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "2999-12-01T09:59:52Z" /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "2024-01-01T10:00:52Z" /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "2999-12-01T09:59:52Z" /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseUpdatesStartTime" /t REG_SZ /d "2024-01-01T09:59:52Z" /f >nul 2>&1
	reg add "%UPDATE_REG%" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "2999-12-01T09:59:52Z" /f >nul 2>&1
	start ms-settings:windowsupdate
	call :sleep "已暂停更新至2999年" 5
) else if "%a%"=="2" (
	echo 正在恢复更新...
	reg delete "%UPDATE_REG%" /v "FlightSettingsMaxPauseDays" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseFeatureUpdatesStartTime" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseFeatureUpdatesEndTime" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseQualityUpdatesStartTime" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseQualityUpdatesEndTime" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseUpdatesStartTime" /f >nul 2>&1
	reg delete "%UPDATE_REG%" /v "PauseUpdatesExpiryTime" /f >nul 2>&1
	start ms-settings:windowsupdate
	call :sleep "已恢复更新" 5
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto windows_update

:: UAC（用户账户控制）设置 子菜单 

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