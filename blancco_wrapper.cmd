@echo off
echo Clean multidisk
echo.
echo last update - 03.04.2019 -- JG
echo.
echo version v0.9.1
echo.
echo START
pushd %~dp0
echo.
echo.

setlocal EnableDelayedExpansion

:: ========  INITIALIZE ENVIROMENT  =========

:: init varialbes
set $blancco_path=''
set $blancco_script_name=''
set $ext_format=''
set $int_format=''
set $hdd=0
set $diskpart_cmd=%temp%\diskpart_cmd.txt

if exist %$diskpart_cmd% del %$diskpart_cmd%

:: read ini file
for /f "skip=2" %%x in ('find "=" config.ini') do (
    set "%%x"
)

:: ========  START PROGRAM  =========

:: validate of variables
:ext
if /i "%$ext_format%"=="ntfs" goto int
if /i "%$ext_format%"=="fat32" goto int
if /i "%$ext_format%"=="exfat" goto int
if /i "%$ext_format%"=="none" goto int
set $error=Bad format for ext_format
goto error

:int
if /i "%$int_format%"=="ntfs" goto variable_ok
if /i "%$int_format%"=="fat32" goto variable_ok
if /i "%$int_format%"=="exfat" goto variable_ok
if /i "%$int_format%"=="none" goto variable_ok
set $error=Bad format for int_format
goto error

:variable_ok
:: check if blancco exist
if not exist %$blancco_path%\%$blancco_script_name%  (
    set $error=No blancco
    goto error
)

:: clean disk
%$blancco_path%\%$blancco_script_name%

:count_disk
:: counting the disks in the machine
::
:: $hdd    number of disks
:: $index  position the disk in diskpart
:: $size   size of the disk

for /f "skip=1 tokens=1,2,3" %%A in ('wmic diskdrive get index^,interfacetype^,size') do (
	if %%B==IDE (
		set $index[!$hdd!]=%%A
		set $tmp=%%C
		set $tmp=!$tmp:~0,-6!
		set $size[!$hdd!]=!$tmp!
        call :func_get_name %%A $hdd_name[!$hdd!]
		set /a $hdd += 1
		)
	if %%B==SCSI (
		set $index[!$hdd!]=%%A
		set $tmp=%%C
		set $tmp=!$tmp:~0,-6!
		set $size[!$hdd!]=!$tmp!
        call :func_get_name %%A $hdd_name[!$hdd!]
		set /a $hdd += 1
	)
    if %%B==USB (
		set $index[!$hdd!]=%%A
		set $tmp=%%C
		set $tmp=!$tmp:~0,-6!
		set $size[!$hdd!]=!$tmp!
        call :func_get_name %%A $hdd_name[!$hdd!]
		set /a $hdd += 1
	)
)


:: prepare script for diskpart
REM cls
echo.
echo.
echo.
echo Creating script.
echo.
echo Found !$hdd! disk[s] 
echo.
set /a $max = !$hdd! - 1
for /L %%I in (0,1,!$max!) do (
    echo hdd name: !$hdd_name[%%I]!
    echo size:     !$size[%%I]! MB
    echo sel dis !$index[%%I]! >> %$diskpart_cmd%
    echo cle >> %$diskpart_cmd%
    call :func_get_answer 
    echo. >> %$diskpart_cmd%
    echo.
)

:: prepare disks
diskpart /s %$diskpart_cmd%
echo.
echo.

goto end

:error
:: error handling
echo Smoething went wrong...
echo.
echo %$error%


goto end
:: ---=== FUNCTIONS ===---

:func_get_name
set $disk_no=%~1
set $name=''
for /f  "skip=1 tokens=2 delims=," %%A in ('wmic diskdrive where index^=%$disk_no% get model  /format:csv^| findstr /R [A-Z]') do (
    set $name=%%A
)
@echo off
set %~2=!$name!
echo.
exit /b 0

:func_get_answer
echo.
:again 
   set /p answer=Is this disk [E]xternal or [I]nternal? 
   if /i "%answer:~,1%" EQU "I" (
        goto ret
   )
   if /i "%answer:~,1%" EQU "E" (
        echo create partition primary >> %$diskpart_cmd%
        echo format fs=exFAT quick >> %$diskpart_cmd%
        goto ret
   )
   goto again
:ret
exit /b 0

:end

echo END
