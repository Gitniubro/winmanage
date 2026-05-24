@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 设备管理
:: 禁用/启用照相机、禁用/启用蓝牙
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
set "title=Windows管理小工具 - 设备管理"
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
call :device_setting
exit /b

:device_setting
setlocal enabledelayedexpansion
call :print_title "设备管理"
set "c="
call :print_separator
echo				1. 照相机开关 &echo.
echo				2. 蓝牙开关 &echo.
echo				0. 返回(q) &echo.
call :print_separator "~" 
echo    通过禁用或开启对应功能来保护系统安全。& echo.
call :print_separator
set /p "c=请选择你要管理的设备: "
if not defined c goto :device_setting
if "%c%"=="0" endlocal & exit /b
if /i "%c%"=="q" endlocal & exit /b
choice /c 123 /n /m "选择你的操作? [1.禁用 2.启用 3.取消]: "
if "%errorlevel%"=="3" goto :device_setting
if "%errorlevel%"=="1" (set "opt=Disable" & set "opt_cn=禁用") else (set "opt=Enable" & set "opt_cn=启用")
if "%c%"=="1" (
	call :device_status_toggle "Camera" %opt%
	call :device_status_toggle "Image" %opt%
	set "device_name=照相机"
)else if "%c%"=="2" (
	call :device_status_toggle "Bluetooth" %opt%
	set "device_name=蓝牙"
)
if defined device_name call :sleep "已%opt_cn%%device_name%" 5
goto :device_setting

:: 设备状态切换
:: 参数1：设备，如Camera
:: 参数2：操作，如Disable、Enable 

:device_status_toggle
set "device=%~1" & set "%opt%=%~2"
powershell.exe -nologo -noprofile -Command "$ProgressPreference = 'SilentlyContinue';Get-PnpDevice -Class %device% | %opt%-PnpDevice -Confirm:$false" >nul 2>&1
exit /b

:: 计算文件的hash值 

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