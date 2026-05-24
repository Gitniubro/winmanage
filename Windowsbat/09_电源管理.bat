@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 电源管理
:: 设置定时关机/重启/休眠（支持分钟数和具体时间）、
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
set "title=Windows管理小工具 - 电源管理"
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
call :power_setting
exit /b

:power_setting
call :print_title "电源管理"
set "a="
call :print_separator
echo				1. 设置定时关机/重启/休眠 &echo.
echo				2. 禁用自动睡眠* &echo.
echo				3. 打开电源选项 &echo.
echo				4. 禁用休眠(删除 hiberfil.sys)* &echo.
echo				5. 启用休眠 &echo.
echo				0. 返回(q) &echo.
call :print_separator "~"
echo 睡眠：保持内存通电，快速恢复(耗电少) 
echo 休眠：将内存数据保存到硬盘 hiberfil.sys 后完全关机(零耗电) &echo.
call :print_separator
echo.
set /p a=请输入你的选择: 
if "%a%"=="1" (
	call :power_schedule
) else if "%a%"=="2" (
	powercfg -change -standby-timeout-ac 0
	powercfg -change -standby-timeout-dc 0
	echo 已禁用自动睡眠 & timeout /t 3
) else if "%a%"=="3" (
	control powercfg.cpl
) else if "%a%"=="4" (
	powercfg -h off
	echo 已禁用休眠 & timeout /t 4
) else if "%a%"=="5" (
	powercfg -h on
	echo 已启用休眠 & timeout /t 4
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto power_setting

::定时关机/重启/休眠 

:power_schedule
setlocal
echo  1.关机  2.重启 3.休眠 4.取消计划
choice /c 1234 /n /m "请选择要执行的操作: "
if "%errorlevel%"=="1" (
    set operation=/s
    set op_name=关机 
) else if "%errorlevel%"=="2" (
    set operation=/r
    set op_name=重启 
) else if "%errorlevel%"=="3" (
    set operation=/h
    set op_name=休眠 
) else if "%errorlevel%"=="4" (
    shutdown /a >nul 2>&1
	if "!errorlevel!"=="1116" (call :sleep "没有正在运行的计划" 5 ) else ( call :sleep "已取消计划" 5)
	endlocal & exit /b
)
echo 1.设置分钟数  2.设置具体时间(HH:MM) 
choice /c 12 /n /m "请选择时间设置方式: "
if "%errorlevel%"=="1" (
    set /p minu="请输入延迟分钟数(默认10分钟): "
    if "!minu!"=="" set "minu=10" 
    set /a seconds=minu*60
) else if "%errorlevel%"=="2" (
    set /p target_time="请输入目标时间 (如 23:30): "
	set target_time=!target_time:：=:!
	for /f %%s in ('powershell -Command "$now = Get-Date; $target = [datetime]::ParseExact(\"!target_time!\", \"HH:mm\", $now.Culture); if ($target -lt $now) { $target = $target.AddDays(1) } ; [int]($target - $now).TotalSeconds"') do (
		set seconds=%%s
	)
)
call :sleep "正在检查注销计划，请稍等..." 1 silent
shutdown /a >nul 2>&1
if "!errorlevel!"=="1116" (call :sleep "没有正在运行的计划" 1 silent) else ( call :sleep "已取消原计划" 1 silent)
call :sleep "正在设置!op_name!，请稍等..." 1 silent
shutdown !operation! /t !seconds!
call :sleep "已设置!op_name!" 10
endlocal & exit /b

:: 系统设置集中管理

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