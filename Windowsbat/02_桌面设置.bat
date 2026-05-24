@echo off & setlocal EnableDelayedExpansion & chcp 65001>nul

:: ============================================================
:: 桌面设置
:: 隐藏/显示桌面图标小箭头、隐藏/显示Windows聚焦、
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
set "title=Windows管理小工具 - 桌面设置"
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
call :desktop
exit /b

:desktop
call :print_title "桌面设置" 
set "a="
call :print_separator
echo			 1. 隐藏桌面图标小箭头                    11. 提取桌面壁纸& echo.
echo			 2. 显示桌面图标小箭头 & echo.
echo			 3. 隐藏了解此图片（windows聚焦） & echo.
echo			 4. 显示了解此图片（windows聚焦） & echo.
echo			 5. 打开桌面图标设置 & echo.
echo			 6. 添加网络连接 & echo.
echo			 7. 添加IE快捷方式& echo.
echo			 8. 显示windows版本水印 & echo.
echo			 9. 隐藏windows版本水印& echo.
echo			10. 设置Bing每日桌面背景& echo.
echo			 0. 返回(q) & echo.
call :print_separator
set /p a=请输入你的选择: 
if "%a%"=="1" (
	echo 正在隐藏桌面图标小箭头...
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /d "%systemroot%\system32\imageres.dll,197" /t reg_sz /f >nul 2>&1
	attrib -s -r -h "%userprofile%\AppData\Local\iconcache.db" >nul 2>&1
	del "%userprofile%\AppData\Local\iconcache.db" /f /q >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="2" (
	echo 正在显示桌面图标小箭头...
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /f >nul 2>&1
	attrib -s -r -h "%userprofile%\AppData\Local\iconcache.db" >nul 2>&1
	del "%userprofile%\AppData\Local\iconcache.db" /f /q >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="3" (
	echo 正在隐藏了解此图片...
	REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 1 /f >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="4" (
	echo 正在显示了解此图片...
	REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /f >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
) else if "%a%"=="5" (
	rundll32 shell32.dll,Control_RunDLL desk.cpl,,0
)else if "%a%"=="6" (
	call :desktop_add_network
	call :sleep "网络连接已添加！" 3
)else if "%a%"=="7" (
	call :desktop_add_ie
	set "add_result=快捷方式创建成功！"
	if %ERRORLEVEL% equ 1 set "add_result=快捷方式创建失败！"
	echo %add_result%！& timeout /t 3
)else if "%a%"=="8" (
	REG ADD "HKCU\Control Panel\Desktop" /V PaintDesktopVersion /T REG_DWORD /D 1 /F >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
)else if "%a%"=="9" (
	REG ADD "HKCU\Control Panel\Desktop" /V PaintDesktopVersion /T REG_DWORD /D 0 /F >nul 2>&1
	call :restart_explorer
	call :sleep "操作完成！" 2
)else if "%a%"=="10" (
	call :set_desktop_background
	call :sleep "10秒后自动返回..." 10
)else if "%a%"=="11" (
	call :GetDesktopWallpaper
)
if "%a%"=="0" exit /b
if /i "%a%"=="q" exit /b
goto desktop

:: 桌面添加网络连接

:desktop_add_network
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$ws = New-Object -ComObject WScript.Shell; ^
$desktop = [Environment]::GetFolderPath('Desktop'); ^
$lnk = $ws.CreateShortcut(\"$desktop\网络连接.lnk\"); ^
$lnk.TargetPath = 'shell:::{7007ACC7-3202-11D1-AAD2-00805FC1270E}'; ^
$lnk.Save()"
exit /b

:: 桌面添加IE快捷方式

:desktop_add_ie
setlocal
set "shortcutName=IE"
set "args=https://www.baidu.com/#ie={inputENcoding}^&wd=%%s -Embedding"
set "programFilesX86=%ProgramFiles(x86)%"
set "targetPath=%programFilesX86%\Internet Explorer\iexplore.exe"
set "workingDir=%programFilesX86%\Internet Explorer"
if not exist "%targetPath%" (
	call :sleep "错误：未找到 Internet Explorer，请确认已安装 IE11 或启用 Windows 功能。" 10
	endlocal & exit /b 1
)
powershell -command "$ws = New-Object -ComObject WScript.Shell; $lnk = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\%shortcutName%.lnk'); $lnk.TargetPath = '%targetPath%'; $lnk.Arguments = '%args%'; $lnk.WorkingDirectory = '%workingDir%'; $lnk.Save()"
echo 快捷方式已创建在桌面：%shortcutName%.lnk
endlocal & exit /b 0

:: 删除桌面快捷方式

:desktop_delete_shortcut
del /f /q "%USERPROFILE%\Desktop\%~1.lnk" 2>nul
exit /b

:: 设置Bing每日桌面背景

:set_desktop_background
setlocal EnableDelayedExpansion
for /f "usebackq delims=" %%P in (`powershell -nologo -noprofile -command "[Environment]::GetFolderPath('MyPictures')"`) do (
    set "downloadDir=%%P\BingWallpapers"
)
if not exist "!downloadDir!" mkdir "!downloadDir!"
echo 正在获取图片信息... 
set "baseUrl=https://www.bing.com"
set "jsonUrl=!baseUrl!/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN&nc=1614319565639&pid=hp&FORM=BEHPTB&uhd=1&uhdwidth=3840&uhdheight=2160"
for /f "usebackq tokens=1,* delims==" %%A in (`
	powershell -nologo -command ^
    "$json = Invoke-RestMethod -Uri '!jsonUrl!' -UseBasicParsing;" ^
    "$img = $json.images[0];" ^
    "Write-Output ('imageUrl=!baseUrl!' + $img.url);" ^
    "Write-Output ('imageName=' + $img.enddate + '_'+ $img.title);" ^
`) do (
    set "%%A=%%B"
)
set "imageFile=!downloadDir!\!imageName!.jpg"
if not exist !imageFile! (
    if "!imageUrl:~20,1!" NEQ "" (
		echo 正在下载图片：!imageName!.jpg
		curl.exe --retry 2 --max-time 30 -so "!imageFile!" "!imageUrl!"
	)
) else echo 图片!imageName!.jpg已存在，跳过下载 
if exist "!imageFile!" (
    echo 正在设置桌面背景...
    powershell -Command "Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class Wallpaper { [DllImport(\"user32.dll\", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }'; [void][Wallpaper]::SystemParametersInfo(20, 0, '!imageFile!', 3)"
	echo 桌面背景已更新为: !imageFile!
) else (
    echo 未能下载或找到图片文件 
)
endlocal & exit /b

:: 提取桌面壁纸

:GetDesktopWallpaper
setlocal enabledelayedexpansion
set "DESKTOP=%USERPROFILE%\Desktop"
set "OUT=%DESKTOP%\DesktopWallpaper.jpg"
set "RESULT=1"
set "MSG=未找到桌面壁纸"
:: 尝试从注册表获取
call :read_reg_value "HKCU\Control Panel\Desktop" "WallPaper"
if defined ret_value if exist "%ret_value%" (
    copy /y "%ret_value%" "%OUT%" >nul
    set "RESULT=0"
)
:: fallback：使用系统缓存
if %RESULT% neq 0 (
    set "CACHE=%APPDATA%\Microsoft\Windows\Themes\TranscodedWallpaper"
    if exist "%CACHE%" (
        copy /y "%CACHE%" "%OUT%" >nul
        set "RESULT=0"
    )
)
:: 统一出口
if %RESULT% equ 0 (
    set "MSG=壁纸已提取到桌面"
)
call :sleep "%MSG%" 4
endlocal & exit /b %RESULT%

:: 任务栏设置 

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