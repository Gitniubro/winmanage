@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 网络管理
:: 查看网络信息、打开网络连接面板、清除 DNS 缓存、
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
set "title=Windows管理小工具 - 网络管理"
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
call :network_setting
exit /b

:network_setting
setlocal enabledelayedexpansion
call :print_title "网络管理"
set "a="
call :print_separator
echo			1. 网络信息                  11. 远程桌面 &echo.
echo			2. 打开网络连接控制面板      12. 一键断网/联网 &echo.
echo			3. 清除DNS缓存               13. 防火墙设置 &echo.
echo			4. MAC地址                   14. 系统代理设置 &echo.
echo			5. ping检查                  15. 端口转发&echo.
echo			6. tracert路由追踪 &echo.
echo			7. 我的外网IP &echo.
echo			8. 检查端口占用 &echo.
echo			9. 测速网 &echo.
echo			10. telnet设置&echo.
echo			0. 返回(q) &echo.
call :print_separator
set /p "a=请输入你的选择: "
if "%a%"=="1" (
	set "command_line=ipconfig /all"
	start "!command_line!" cmd /k "!command_line!"
) else if "%a%"=="2" (
	start ncpa.cpl
) else if "%a%"=="3" (
	ipconfig /flushdns
	call :sleep " " 4
) else if "%a%"=="4" (
	echo.
	getmac /v & pause
) else if "%a%"=="5" (
	echo.
	set "ping_target="
	set /p "ping_target=请输入要ping的IP或域名[默认: baidu.com]: "
	if "!ping_target!"=="" set "ping_target=baidu.com"
	call :ask_confirm "是否持续检查? [y/N]: " n
	if errorlevel 1 (
		set "ping_cmd=ping !ping_target! -t"
	) else (
		set "ping_cmd=ping !ping_target! -n 4"
	)
	start "Ping检查: !ping_target!" cmd /k "!ping_cmd!"
) else if "%a%"=="6" (
	echo.
	set "trace_target="
	set /p "trace_target=请输入要追踪的IP或域名[默认: baidu.com]: "
	if "!trace_target!"=="" set "trace_target=baidu.com"
	start "路由追踪: !trace_target!" cmd /k "tracert -d -w 1000 !trace_target!"
) else if "%a%"=="7" (
	echo.
	curl.exe -s -L --connect-timeout 5 --max-time 10 https://myip.ipip.net/
	echo https://myip.ipip.net 提供服务支持 & pause
) else if "%a%"=="8" (
	call :search_port
	call :sleep "end.." 5
) else if "%a%"=="9" (
	start "" https://www.speedtest.cn/
) else if "%a%"=="10" (
	call :telnet_setting
) else if "%a%"=="11" (
	call :remote_desktop
) else if "%a%"=="12" (
	call :internet_control
	if "!errorlevel!"=="1" (set "net_status=断网") else (set "net_status=联网")
	call :sleep "已设置!net_status!！" 5
) else if "%a%"=="13" (
	call :advfirewall_setting
) else if "%a%"=="14" (
	call :system_proxy
) else if "%a%"=="15" (
	call :port_forward
)
if "%a%"=="0" endlocal & exit /b
if /i "%a%"=="q" endlocal &  exit /b
goto :network_setting 


:search_port
set "S_PORT="
set /p S_PORT=请输入要查询的端口号： 
if not defined S_PORT exit /b
set "FOUND_PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%S_PORT% ^| findstr LISTENING') do (
    set "FOUND_PID=%%a"
    call :process_pid !FOUND_PID!
    exit /b
)
echo 没有发现有程序占用端口 %S_PORT%
exit /b


:process_pid
set "K_PID=%~1"
echo 端口 %S_PORT% 被占用，PID：%K_PID%
set "K_EXE="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "Try { (Get-Process -Id %K_PID%).Path } Catch { '' }"`) do (
    set "K_EXE=%%p"
)
if defined K_EXE (
    echo 占用程序路径：!K_EXE!
) else (
    echo 无法获取进程路径（可能是系统进程或权限不足）。
	exit /b
)
set "K_KILL="
set /p K_KILL=是否结束该进程？(y/N)： 
if /i "!K_KILL!"=="Y" (
    taskkill /PID %K_PID% /F
)
exit /b

:: telnet设置 

:telnet_setting
setlocal enabledelayedexpansion
call :print_title "telnet设置"
set "a="
call :print_separator
echo			1. 安装telnet客户端 &echo.
echo			2. telehack.com&echo.
echo			0. 返回(q) &echo.
call :print_separator
set /p "a=请输入你的选择: "
if "%a%"=="1" (
	call :install_telnet
) else if "%a%"=="2" (
	call :start_telehack
)
if "%a%"=="0" endlocal & exit /b
if /i "%a%"=="q" endlocal &  exit /b
goto :telnet_setting 

:: 安装telnet客户端 

:install_telnet
powershell -Command "(Get-WindowsOptionalFeature -Online -FeatureName TelnetClient).State -eq 'Enabled'" | findstr "True" >nul
if %errorlevel% neq 0 (
    echo 安装 telnet 客户端... 
    powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient -All"
	call :sleep "telnet安装完成!" 4
) else (
	call :sleep "telnet客户端已经安装" 4
)
exit /b

:: 打开telehack

:start_telehack
echo. & echo Telehack是ARPANET和Usenet的风格化界面的在线模拟，于2010年匿名创建。它是一个完整的多用户模拟，包括26,600+模拟主机，其文件时间跨度为1985年至1990年。 
echo.
call :wait_keydown "回车开始"
start cmd /k "telnet telehack.com"
exit /b

:: 远程桌面 

:remote_desktop
setlocal
choice /c 123 /n /m "远程桌面设置? [1.启用 2.关闭 3.返回]: "
if "%errorlevel%"=="3" exit /b
if "%errorlevel%"=="1" (set "value=0") else ( set "value=1")
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d %value% /f
call :sleep "远程桌面设置成功" 5
endlocal & exit /b

:: 一键联网控制 

:internet_control
choice /c 12 /n /m "一键联网控制? [1.断网 2.联网]: "
if "%errorlevel%"=="1" (
	powershell -Command "$ProgressPreference = 'SilentlyContinue';Get-NetAdapter | Disable-NetAdapter -Confirm:$false"
	exit /b 1
) else (
	powershell -Command "$ProgressPreference = 'SilentlyContinue';Get-NetAdapter | Enable-NetAdapter -Confirm:$false"
	exit /b 2
)

:: 防火墙设置 

:advfirewall_setting
set "firwall_c="
choice /c 1234 /n /m "防火墙设置 [1.关闭 2.开启 3.重置 4.手动]: "
if "%errorlevel%"=="1" (
	netsh advfirewall set allprofiles state off >nul 2>&1
	call :sleep "防火墙已关闭" 3
) else if "%errorlevel%"=="2" (
	netsh advfirewall set allprofiles state on >nul 2>&1
	call :sleep "防火墙已开启" 3
) else if "%errorlevel%"=="3" (
	netsh advfirewall set allprofiles state reset >nul 2>&1
	call :sleep "防火墙已重置" 3
) else if "%errorlevel%"=="4" (
	start "" wf.msc
)
exit /b

:: 系统代理 

:system_proxy
call :print_title "系统代理设置"
set "sp="
set "system_proxy_reg_location=HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
call :print_separator
echo				1. 设置代理 &echo.
echo				2. 关闭代理 &echo.
echo				3. 当前状态 &echo.
echo				4. 打开系统代理设置界面 &echo.
echo				0. 返回(q) &echo.
call :print_separator
set /p "sp=请输入你的选择: "
if "%sp%"=="1" ( 
	set /p proxy_ip_port="请输入代理服务器地址及端口（例如 127.0.0.1:8099）: "
	set proxy_ip_port=!proxy_ip_port:：=:!
	echo.
	echo 正在设置代理 !proxy_ip_port! ...
	reg add "!system_proxy_reg_location!" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
	reg add "!system_proxy_reg_location!" /v ProxyServer /t REG_SZ /d "!proxy_ip_port!" /f >nul
	reg add "!system_proxy_reg_location!" /v ProxyOverride /t REG_SZ /d "<local>" /f >nul
	call :sleep "代理已设置为 !proxy_ip_port!" 5
) else if "%sp%"=="2" (
	reg add "!system_proxy_reg_location!" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
	reg delete "!system_proxy_reg_location!" /v ProxyServer /f >nul 2>nul
	reg add "!system_proxy_reg_location!" /v ProxyOverride /t REG_SZ /d "" /f >nul
	call :sleep "代理已关闭" 3
) else if "%sp%"=="3" (
	call :read_reg_value "!system_proxy_reg_location!" "ProxyEnable"
	if "!ret_value!"=="0x1" (
		echo 代理启用状态: 已启用
		call :read_reg_value "!system_proxy_reg_location!" "ProxyServer"
		echo 当前代理服务器: !ret_value!
	) else if "!ret_value!"=="0x0" (
		echo 代理启用状态: 已关闭 
	) else echo 无法读取代理状态（可能未设置） 
	pause
) else if "%sp%"=="4" (
	start ms-settings:network-proxy
)
if "%sp%"=="0" exit /b
if /i "%sp%"=="q" exit /b
goto :system_proxy

:: 端口转发 

:port_forward
call :print_title "端口转发"
set "pf="
call :print_separator
echo				1. 添加端口转发规则 &echo.
echo				2. 删除端口转发规则 &echo.
echo				3. 查看当前规则 &echo.
echo				4. 清空所有规则 &echo.
echo				0. 返回(q) &echo.
call :print_separator
set /p "pf=请输入你的选择: "
if "%pf%"=="1" (
	echo 添加端口转发规则...&echo.
	set /p "listen_ip_port=请输入监听IP地址及端口(例如：127.0.0.1:8999):"
	set /p "connect_ip_port=请输入目标IP地址及端口(例如：127.0.0.1:8080):"
	set "listen_ip_port=!listen_ip_port:： =:!"
	set "connect_ip_port=!connect_ip_port:： =:!"
	for /f "tokens=1,2 delims=:" %%a in ("!listen_ip_port!") do (set "listen_ip=%%a" & set "listen_port=%%b")
	for /f "tokens=1,2 delims=:" %%a in ("!connect_ip_port!") do (set "connect_ip=%%a" & set "connect_port=%%b")
	netsh interface portproxy add v4tov4 listenaddress=!listen_ip! listenport=!listen_port! connectaddress=!connect_ip! connectport=!connect_port!
	call :sleep "添加完成" 10
) else if "%pf%"=="2" (
	echo 删除端口转发规则...&echo.
	set /p "listen_ip_port=请输入要删除的监听IP地址及端口(例如：127.0.0.1:8999):"
	set "listen_ip_port=!listen_ip_port:： =:!"
	for /f "tokens=1,2 delims=:" %%a in ("!listen_ip_port!") do (set "listen_ip=%%a" & set "listen_port=%%b")
	netsh interface portproxy delete v4tov4 listenaddress=!listen_ip! listenport=!listen_port!
	call :sleep "删除完成" 10
) else if "%pf%"=="3" (
	echo 当前转发规则 
	netsh interface portproxy show all
	call :wait_keydown "按任意键继续"
) else if "%pf%"=="4" (
	netsh interface portproxy reset
	call :wait_keydown "规则已清空，按任意键继续"
)
if "%pf%"=="0" exit /b
if /i "%pf%"=="q" exit /b
goto :port_forward

:: 设备管理 

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