@setlocal DisableDelayedExpansion
@echo off

:: Add custom name in IDM license info, prefer to write it in English and/or numeric in below line after = sign,
set name=Piash YooooooDaLi@52pojie




::========================================================================================================================================

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

if exist %SystemRoot%\Sysnative\cmd.exe (
set "_cmdf=%~f0"
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\Windows\SyChpe32\kernel32.dll if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 (
set "_cmdf=%~f0"
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

::  Set Path variable, it helps if it is misconfigured in the system

set "SysPath=%SystemRoot%\System32"
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"

::========================================================================================================================================

cls
color 07

set _args=
set _elev=
set reset=
set Silent=
set activate=

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"  set _elev=1
if /i "%%A"=="/res" set Unattended=1&set activate=&set reset=1
if /i "%%A"=="/act" set Unattended=1&set activate=1&set reset=
if /i "%%A"=="/s"   set Unattended=1&set Silent=1
)
)

::========================================================================================================================================

set "nul=>nul 2>&1"
set "_psc=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
call :_colorprep
set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "line=________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

if defined Silent if not defined activate if not defined reset exit /b
if defined Silent call :begin %nul% & exit /b

:begin

::========================================================================================================================================

if not exist "%_psc%" (
%nceline%
echo 系统中未安装Powershell.
echo 正在退出...
goto done2
)

if %winbuild% LSS 7600 (
%nceline%
echo 检测到不支持的系统版本.
echo 该项目只支持Windows 7/8/8.1/10/11及其服务器版本.
goto done2
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name
::  Thanks to @abbodi1406

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_appdata=%appdata%"
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\DownloadManager" /v ExePath 2^>nul') do call set "IDMan=%%b"

setlocal EnableDelayedExpansion

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop
::  Thanks to @abbodi1406 for the powershell method and solving special characters issue in file path name.

%nul% reg query HKU\S-1-5-19 || (
if not defined _elev %nul% %_psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%nceline%
echo 该脚本需要管理员权限以运行.
echo 要使其以管理员权限运行, 你需要右键单击此脚本并选择'以管理员权限运行'.
goto done2
)

::========================================================================================================================================

:: Below code also works for ARM64 Windows 10 (including x64 bit emulation)

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" /v "Identifier" | find /i "x86" 1>nul && set arch=x86|| set arch=x64

if not exist "!IDMan!" (
if %arch%==x64 set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
if %arch%==x86 set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

if "%arch%"=="x86" (
set "CLSID=HKCU\Software\Classes\CLSID"
set "HKLM=HKLM\Software\Internet Download Manager"
set "_tok=5"
) else (
set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
set "_tok=6"
)

set _temp=%SystemRoot%\Temp
set regdata=%SystemRoot%\Temp\regdata.txt
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" >nul"

::========================================================================================================================================

if defined Unattended (
if defined reset goto _reset
if defined activate goto _activate
)

:MainMenu
chcp 65001
cls
title  IDM Activation Script
mode 65, 25

:: Check firewall status

set /a _ena=0
set /a _dis=0
for %%# in (DomainProfile PublicProfile StandardProfile) do (
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
if /i %%b equ 0x1 (set /a _ena+=1) else (set /a _dis+=1)
)
)

if %_ena%==3 (
set _status=Enabled
set _col=%_Green%
)

if %_dis%==3 (
set _status=Disabled
set _col=%_Red%
)

if not %_ena%==3 if not %_dis%==3 (
set _status=Status_Unclear
set _col=%_Yellow%
)
		

echo:"           ─▀▀▌───────▐▀▀"
echo:"           ─▄▀░◌░░░░░░░▀▄        ◇────────────────────◇"
echo:"           ▐░░◌░▄▀██▄█░░░▌        IDM 激活脚本"
echo:"           ▐░░░▀████▀▄░░░▌       ◇────────────────────◇"
echo:"           ═▀▄▄▄▄▄▄▄▄▄▄▄▀═"
echo:
call :_color2 %_White% "        " %_Green% "  作者: Piash 汉化: 52pojie YooooooDaLi"           
echo:          _____________________________________________  
echo:          
echo:          [1] 激活IDM                                
echo:          [2] 重设IDM激活信息 / 试用信息
echo:          _____________________________________________   
echo:                                                          
call :_color2 %_White% "          [3] 切换Windows防火墙状态  " %_col% "[%_status%]"
echo:          _____________________________________________   
echo:                                                          
echo:          [4] ReadMe                                      
echo:          [5] 打开主页                                   
echo:          [6] 退出程序                                        
echo:       ___________________________________________________
echo:   
call :_color2 %_White% "        " %_Green% "在键盘上输入 [1,2,3,4,5,6] 并回车以执行操作"
choice /C:123456 /N
set _erl=%errorlevel%

if %_erl%==5 exit /b
if %_erl%==4 goto homepage
if %_erl%==3 call :_tog_Firewall&goto MainMenu
if %_erl%==2 goto _reset
if %_erl%==1 goto _activate
goto :MainMenu

::========================================================================================================================================

:_tog_Firewall

if %_status%==Enabled (
netsh AdvFirewall Set AllProfiles State Off >nul
) else (
netsh AdvFirewall Set AllProfiles State On >nul
)
exit /b

::========================================================================================================================================

:readme

set "_ReadMe=%SystemRoot%\Temp\ReadMe.txt"
if exist "%_ReadMe%" del /f /q "%_ReadMe%" %nul%
call :export txt "%_ReadMe%"
start notepad "%_ReadMe%"
timeout /t 2 %nul%
del /f /q "%_ReadMe%"
exit /b


::  Extract the text from batch script without character and file encoding issue
::  Thanks to @abbodi1406

:export

%nul% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split \":%~1\:.*`r`n\"; [io.file]::WriteAllText('%~2',$f[1].Trim(),[System.Text.Encoding]::ASCII);"
exit/b

::========================================================================================================================================

:_reset

if not defined Unattended (
mode 93, 32
%nul% %_psc% "&%_buf%"
)

echo:
set _error=

reg query "HKCU\Software\DownloadManager" "/v" "Serial" %nul% && (
%idmcheck% && taskkill /f /im idman.exe
)

if exist "!_appdata!\DMCache\settings.bak" del /s /f /q "!_appdata!\DMCache\settings.bak"

set "_action=call :delete_key"
call :reset

echo:
echo %line%
echo:
if not defined _error (
call :_color %Green% "IDM Activation - Trial is successfully reset in the registry."
) else (
call :_color %Red% "Failed to completely reset IDM Activation - Trial."
)

goto done

::========================================================================================================================================

:_activate

if not defined Unattended (
mode 93, 32
%nul% %_psc% "&%_buf%"
)

echo:
set _error=

if not exist "!IDMan!" (
call :_color %Red% "IDM [Internet Download Manager] 未安装."
echo 你可以从  https://www.internetdownloadmanager.com/download.html 下载IDM
goto done
)

:: Internet check with internetdownloadmanager.com ping and port 80 test

ping -n 1 internetdownloadmanager.com >nul || (
%_psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i true 1>nul
)

if not [%errorlevel%]==[0] (
call :_color %Red% "无法连接至 internetdownloadmanager.com, 正在退出..."
goto done
)

echo 网络已连接.

%idmcheck% && taskkill /f /im idman.exe

if exist "!_appdata!\DMCache\settings.bak" del /s /f /q "!_appdata!\DMCache\settings.bak"

set "_action=call :delete_key"
call :reset

set "_action=call :count_key"
call :register_IDM

echo:
if defined _derror call :f_reset & goto done

set lockedkeys=
set "_action=call :lock_key"
echo 正在锁定注册表值...
echo:
call :action

if not defined _error if [%lockedkeys%] GEQ [7] (
echo:
echo %line%
echo:
call :_color %Green% "IDM 成功激活."
echo:
call :_color %Gray% "如果程序弹窗提示非法序列号，尝试重新运行此脚本。之后该窗口应该不会再次出现."
goto done
)

call :f_reset

::========================================================================================================================================

:done

echo %line%
echo:
echo:
if defined Unattended (
timeout /t 3
exit /b
)

call :_color %_Yellow% "按下任意键以退出..."
pause >nul
goto MainMenu

:done2

if defined Unattended (
timeout /t 3
exit /b
)

echo 按下任意键以退出...
pause >nul
exit /b

::========================================================================================================================================

:homepage

cls
echo:
echo:
echo 正在退出...
echo:
echo:
timeout /t 3

start https://github.com/lstprjct/IDM-Activation-Script
goto MainMenu

::========================================================================================================================================

:f_reset

echo:
echo %line%
echo:
call :_color %Red% "激活过程中出现错误，正在重启IDM激活..."
set "_action=call :delete_key"
call :reset
echo:
echo %line%
echo:
call :_color %Red% "无法激活IDM."
exit /b

::========================================================================================================================================

:reset

set take_permission=
call :delete_queue
set take_permission=1
call :action
call :add_key
exit /b

::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :_add_key
exit /b

:register_IDM

echo:
echo 应用激活信息中...
echo:

If not defined name set name=Piash

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%name%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d """ & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "info@tonec.com"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "FOX6H-3KWH4-7TSIN-Q4US7"" & call :_rcont

echo:
echo 触发一些下载以创建对应的注册表值...

set "file=%_temp%\temp.png"
set _fileexist=
set _derror=

%idmcheck% && taskkill /f /im idman.exe

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download

:: it may take some time to reflect registry keys.
timeout /t 3 >nul

set foundkeys=
call :action
if [%foundkeys%] GEQ [7] goto _skip

set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download
set link=https://www.internetdownloadmanager.com/languages/indian.png
call :download

timeout /t 3 >nul

set foundkeys=
call :action
if not [%foundkeys%] GEQ [7] set _derror=1

:_skip

echo:
if not defined _derror (
echo 需要的注册表值被成功创建.
) else (
if not defined _fileexist call :_color %Red% "无法使用IDM下载文件."
call :_color %Red% "创建注册表值失败."
call :_color %Magenta% "尝试以下操作 - 使用脚本选项禁用Windows防火墙 - 检查Read Me文件."
)

echo:
%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%"
exit /b

:download

set /a attempt=0
if exist "%file%" del /f /q "%file%"
start "" /B "!IDMan!" /n /d "%link%" /p "%_temp%" /f temp.png

:check_file

timeout /t 1 >nul
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 20 exit /b
goto :Check_file

::========================================================================================================================================

:delete_queue

echo:
echo 正在删除注册表值，可能需要一些时间...
echo:

for %%# in (
""HKCU\Software\DownloadManager" "/v" "FName""
""HKCU\Software\DownloadManager" "/v" "LName""
""HKCU\Software\DownloadManager" "/v" "Email""
""HKCU\Software\DownloadManager" "/v" "Serial""
""HKCU\Software\DownloadManager" "/v" "scansk""
""HKCU\Software\DownloadManager" "/v" "tvfrdt""
""HKCU\Software\DownloadManager" "/v" "radxcnt""
""HKCU\Software\DownloadManager" "/v" "LstCheck""
""HKCU\Software\DownloadManager" "/v" "ptrk_scdt""
""HKCU\Software\DownloadManager" "/v" "LastCheckQU""
"%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :delete_key
)

exit /b

::========================================================================================================================================

:add_key

echo:
echo 正在添加注册表值...
echo:

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:_add_key

if [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo Added - !reg!
) else (
set _error=1
set "reg=%reg:"=%"
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline&echo  - !reg!
)
exit /b

::========================================================================================================================================

:action

if exist %regdata% del /f /q %regdata% %nul%

reg query %CLSID% > %regdata%

%nul% %_psc% "(gc %regdata%) -replace 'HKEY_CURRENT_USER', 'HKCU' | Out-File -encoding ASCII %regdata%"

for /f %%a in (%regdata%) do (
for /f "tokens=%_tok% delims=\" %%# in ("%%a") do (
echo %%#|findstr /r "{.*-.*-.*-.*-.*}" >nul && (set "reg=%%a" & call :scan_key)
)
)

if exist %regdata% del /f /q %regdata% %nul%

exit /b

::========================================================================================================================================

:scan_key

reg query %reg% 2>nul | findstr /i "LocalServer32 InProcServer32 InProcHandler32" >nul && exit /b

reg query %reg% 2>nul | find /i "H" 1>nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a|findstr /r /e "[^0-9]" >nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=3" %%a in ('reg query %reg%\Version /ve 2^>nul') do echo %%a|findstr /r "[^0-9]" >nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=1" %%a in ('reg query %reg% 2^>nul') do echo %%a| findstr /i "MData Model scansk Therad" >nul && (
%_action%
exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a| find /i "+" >nul && (
%_action%
exit /b
)

exit/b

::========================================================================================================================================

:delete_key

reg delete %reg% /f %nul%

if not [%errorlevel%]==[0] if defined take_permission (
%nul% call :reg_own "%reg%" preserve S-1-1-0
reg delete %reg% /f %nul%
)

if [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo 已删除注册表值 - !reg!
) else (
set "reg=%reg:"=%"
set _error=1
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline & echo  - !reg!
)

exit /b

::========================================================================================================================================

:lock_key

%nul% call :reg_own "%reg%" "" S-1-1-0 S-1-0-0 Deny "FullControl"

reg delete %reg% /f %nul%

if not [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo Locked - !reg!
set /a lockedkeys+=1
) else (
set _error=1
set "reg=%reg:"=%"
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline&echo  - !reg!
)

exit /b

::========================================================================================================================================

:count_key

set /a foundkeys+=1
exit /b

::========================================================================================================================================

::  A lean and mean snippet to set registry ownership and permission recursively
::  Written by @AveYo aka @BAU
::  pastebin.com/XTPt0JSC

:reg_own

%_psc% $A='%~1','%~2','%~3','%~4','%~5','%~6';iex(([io.file]::ReadAllText('!_batp!')-split':Own1\:.*')[1])&exit/b:Own1:
$D1=[uri].module.gettype('System.Diagnostics.Process')."GetM`ethods"(42) |where {$_.Name -eq 'SetPrivilege'} #`:no-ev-warn
'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege'|foreach {$D1.Invoke($null, @("$_",2))}
$path=$A[0]; $rk=$path-split'\\',2; $HK=gi -lit Registry::$($rk[0]) -fo; $s=$A[1]; $sps=[Security.Principal.SecurityIdentifier]
$u=($A[2],'S-1-5-32-544')[!$A[2]];$o=($A[3],$u)[!$A[3]];$w=$u,$o |% {new-object $sps($_)}; $old=!$A[3];$own=!$old; $y=$s-eq'all'
$rar=new-object Security.AccessControl.RegistryAccessRule( $w[0], ($A[5],'FullControl')[!$A[5]], 1, 0, ($A[4],'Allow')[!$A[4]] )
$x=$s-eq'none';function Own1($k){$t=$HK.OpenSubKey($k,2,'TakeOwnership');if($t){0,4|%{try{$o=$t.GetAccessControl($_)}catch{$old=0}
};if($old){$own=1;$w[1]=$o.GetOwner($sps)};$o.SetOwner($w[0]);$t.SetAccessControl($o); $c=$HK.OpenSubKey($k,2,'ChangePermissions')
$p=$c.GetAccessControl(2);if($y){$p.SetAccessRuleProtection(1,1)};$p.ResetAccessRule($rar);if($x){$p.RemoveAccessRuleAll($rar)}
$c.SetAccessControl($p);if($own){$o.SetOwner($w[1]);$t.SetAccessControl($o)};if($s){$subkeys=$HK.OpenSubKey($k).GetSubKeyNames()
foreach($n in $subkeys){Own1 "$k\$n"}}}};Own1 $rk[1];if($env:VO){get-acl Registry::$path|fl} #:Own1: lean & mean snippet by AveYo

::========================================================================================================================================

:_color

if %winbuild% GEQ 10586 (
echo %esc%[%~1%~2%esc%[0m
) else (
call :batcol %~1 "%~2"
)
exit /b

:_color2

if %winbuild% GEQ 10586 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
call :batcol %~1 "%~2" %~3 "%~4"
)
exit /b

::=======================================

:: Colored text with pure batch method
:: Thanks to @dbenham and @jeb
:: https://stackoverflow.com/a/10407642

:: Powershell is not used here because its slow

:batcol

pushd %_coltemp%
if not exist "'" (<nul >"'" set /p "=.")
setlocal
set "s=%~2"
set "t=%~4"
call :_batcol %1 s %3 t
del /f /q "'"
del /f /q "`.txt"
popd
exit /b

:_batcol

setlocal EnableDelayedExpansion
set "s=!%~2!"
set "t=!%~4!"
for /f delims^=^ eol^= %%i in ("!s!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~1 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
if "%~4"=="" echo(&exit /b
setlocal EnableDelayedExpansion
for /f delims^=^ eol^= %%i in ("!t!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~3 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
echo(
exit /b

::=======================================

:_colorprep

if %winbuild% GEQ 10586 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"

set     "Red="41;97m""
set    "Gray="100;97m""
set   "Black="30m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "Yellow="43;97m""
set "Magenta="45;97m""

set    "_Red="40;91m""
set  "_Green="40;92m""
set   "_Blue="40;94m""
set  "_White="40;37m""
set "_Yellow="40;93m""

exit /b
)

if not defined _BS for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"
set "_coltemp=%SystemRoot%\Temp"

set     "Red="CF""
set    "Gray="8F""
set   "Black="00""
set   "Green="2F""
set    "Blue="1F""
set  "Yellow="6F""
set "Magenta="5F""

set    "_Red="0C""
set  "_Green="0A""
set   "_Blue="09""
set  "_White="07""
set "_Yellow="0E""

exit /b

::========================================================================================================================================

:txt:
激活：
_________________________________

 - 该脚本采用注册表锁定方法来激活Internet Download Manager（IDM）。

 - 此方法在激活时需要互联网连接。

 - IDM更新可以直接安装，无需再次激活。

 - 在激活后，如果在某些情况下IDM开始显示激活提示屏幕，
   只需再次运行激活选项。

_________________________________

重置IDM激活/试用期：
_________________________________

 - Internet Download Manager提供30天的试用期，您可以使用此脚本在需要时重置此激活/试用期。
 
 - 如果IDM报告虚假序列号和其他类似错误，也可以使用此选项恢复状态。

_________________________________

操作系统要求：
_________________________________

 - 该项目仅支持Windows 7/8/8.1/10/11及其服务器等效版本。

_________________________________

 - 高级信息：
_________________________________

   - 要在IDM许可信息中添加自定义名称，请编辑脚本文件中的第5行。
   - 要在无人值守模式下进行激活，请使用/act参数运行脚本。
   - 要在无人值守模式下进行重置，请使用/res参数运行脚本。
   - 要在上述两种方法中启用静默模式，请使用/s参数运行脚本。

可接受的值，

"IAS_xxxxxxxx.cmd" /act
"IAS_xxxxxxxx.cmd" /res
"IAS_xxxxxxxx.cmd" /act /s
"IAS_xxxxxxxx.cmd" /res /s

_________________________________

 - 故障排除步骤：
_________________________________

   - 如果以前使用过任何其他激活工具来激活IDM，请务必使用该同一激活工具正确卸载它
     （如果有选项的话），这尤其重要，如果使用了任何注册表/防火墙阻止方法。

   - 从控制面板中卸载IDM。

   - 确保使用最新的原版IDM安装程序进行安装，
     您可以从https://www.internetdownloadmanager.com/download.html下载。

   - 现在安装IDM，如果在此脚本中使用激活选项失败，则执行以下操作：

     - 使用脚本选项禁用Windows防火墙，这有助于清除先前使用的激活工具遗留的条目
       （某些文件修补方法还会创建防火墙条目）。

     - 一些安全程序可能会阻止此脚本运行，这是误报，只要您从原始帖子（在本页面下方提到）中下载了文件，
       暂时暂停防病毒实时保护，或将下载的文件/提取的文件夹排除在扫描之外。

     - 如果您仍然遇到任何问题，请与我联系（在本页面下方提到）。

__________________________________________________________________________________________________

   鸣谢：
__________________________________________________________________________________________________

   @Dukun Cabul		- IDM试用重置和激活逻辑的原始研究人员，
			  为这些方法制作了一个Autoit工具，IDM-AIO_2020_Final
			  nsaneforums.com/topic/371047--/?do=findComment&comment=1632062
                         
   @WindowsAddict	- 将上述Autoit工具移植到批处理脚本中

   @AveYo aka @BAU	- 用于递归设置注册表所有权和权限的代码片段
			  pastebin.com/XTPt0JSC

   @abbodi1406		- 出色的批处理脚本技巧和帮助

   @dbenham		- 独立于窗口高度设置缓冲区高度
			  stackoverflow.com/a/13351373

   @ModByPiash（我）	- 添加并修复了一些缺失的功能。

   @vavavr00m  		- 将设置名称更改为提示输入名称

   @LazyDevv		- 在主菜单中添加了可爱的金鱼艺术。
   
_________________________________

   IDM激活脚本
   
   主页：	https://github.com/lstprjct/IDM-Activation-Script
   
   电报群：	https://t.me/ModByPiash

__________________________________________________________________________________________________
:txt:

::========================================================================================================================================
