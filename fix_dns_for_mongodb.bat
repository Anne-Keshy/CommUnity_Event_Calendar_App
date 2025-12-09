@echo off
REM Change DNS to Google Public DNS (8.8.8.8) to resolve MongoDB Atlas
REM Run as Administrator

setlocal enabledelayedexpansion

echo ================================================================================
echo Changing DNS to Google Public DNS (8.8.8.8 and 8.8.4.4)
echo ================================================================================
echo.
echo Current DNS (before change):
ipconfig /all | findstr "DNS Servers"
echo.

REM Get the network interface name
for /f "tokens=2 delims=: " %%A in ('ipconfig /all ^| findstr "Wi-Fi"') do (
    echo Detected Wi-Fi adapter
    echo.
    echo Running: netsh interface ip set dns "Wi-Fi" static 8.8.8.8
    netsh interface ip set dns "Wi-Fi" static 8.8.8.8
    
    echo Running: netsh interface ip add dns "Wi-Fi" 8.8.4.4 index=2
    netsh interface ip add dns "Wi-Fi" 8.8.4.4 index=2
    goto done
)

:done
echo.
echo ================================================================================
echo DNS Changed Successfully!
echo ================================================================================
echo.
echo New DNS (after change):
ipconfig /all | findstr "DNS Servers"
echo.
echo Flushing DNS cache...
ipconfig /flushdns
echo DNS cache flushed.
echo.
echo Now try connecting to MongoDB Atlas again:
echo   python test_atlas_connection.py
echo.
pause
