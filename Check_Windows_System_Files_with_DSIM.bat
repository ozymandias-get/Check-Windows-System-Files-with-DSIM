@echo off
:: Check for administrative privileges and elevate if necessary
>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Administrative permissions are required...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: Run the DISM command
chcp 65001 >nul & set /p start_dism="Press Enter to start: "
echo Running DISM command...
DISM.exe /Online /Cleanup-image /Restorehealth
if '%errorlevel%' NEQ '0' (
    echo DISM command was stopped.
    goto END
)
echo DISM command completed.

:: Wait for 180 seconds or interrupt
:WAIT_180_SECONDS
echo Waiting for 180 seconds...
set /a counter=180
:WAIT_LOOP
if %counter%==0 goto RUN_SFC
chcp 65001 >nul & set /p dummy="Press Enter to skip waiting or wait: " <nul
if errorlevel 0 (
    echo Waiting period interrupted.
    goto RUN_SFC
)
timeout /t 1 >nul
set /a counter-=1
goto WAIT_LOOP

:: Run the SFC command
:RUN_SFC
echo Running SFC command...
sfc /scannow
if '%errorlevel%' NEQ '0' (
    echo SFC command was stopped.
    goto END
)
echo SFC command completed.

:: Restart prompt
:ASK_RESTART
echo Do you want to restart the computer? (Y/N)
chcp 65001 >nul & set /p restart_choice="Your choice (Y/N): "
if /i "%restart_choice%"=="Y" (
    echo Restarting the computer...
    shutdown /r /t 0
) else if /i "%restart_choice%"=="N" (
    echo The computer will not be restarted.
    goto END
) else (
    echo Invalid choice. Please enter Y or N.
    goto ASK_RESTART
)

:END
echo Process completed. Press any key to exit.
pause >nul
