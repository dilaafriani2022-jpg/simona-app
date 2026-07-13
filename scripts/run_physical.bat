@echo off
setlocal enabledelayedexpansion

:: Masuk ke folder tempat file bat ini berada secara otomatis (mencegah error jika dipanggil dari folder lain)
cd /d "%~dp0.."

echo ========================================================
echo [MONAK] Mendeteksi IP Wi-Fi PC...
echo ========================================================

:: Get active Wi-Fi IPv4 address
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -InterfaceAlias 'Wi-Fi' -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress"`) do (
    set "WIFI_IP=%%i"
)

:: Fallback if Wi-Fi IP not found (e.g. interface named differently)
if "%WIFI_IP%"=="" (
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -notlike '127.*' | Where-Object IPAddress -notlike '169.254.*' | Select-Object -First 1).IPAddress"`) do (
        set "WIFI_IP=%%i"
    )
)

if "%WIFI_IP%"=="" (
    echo [ERROR] Tidak dapat menemukan IP Address Wi-Fi aktif.
    echo Pastikan laptop Anda terhubung ke Wi-Fi.
    pause
    exit /b
)

echo [MONAK] IP Wi-Fi Terdeteksi: %WIFI_IP%

:: Update physicalDeviceUrl in lib/services/api_service.dart
powershell -NoProfile -Command ^
    "$file = 'lib/services/api_service.dart';" ^
    "$content = Get-Content $file -Raw;" ^
    "$pattern = 'static const String physicalDeviceUrl = \".*?\";';" ^
    "$replacement = 'static const String physicalDeviceUrl = \"http://' + '%WIFI_IP%' + '/monak/backend\";';" ^
    "$content -replace $pattern, $replacement | Set-Content $file"

echo [MONAK] file api_service.dart telah diperbarui otomatis!
echo [MONAK] Menjalankan: flutter run
echo ========================================================

flutter run
