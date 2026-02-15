@echo off
echo Fixing Functions Dependencies...

REM Switch to the script's directory (functions folder)
cd /d "%~dp0"

REM Add common Node.js paths to PATH for this session
set "PATH=%PATH%;C:\Program Files\nodejs;C:\Program Files (x86)\nodejs"

REM Check if node is accessible
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is still not found!
    echo Please ensure Node.js is installed.
    pause
    exit /b 1
)

echo Installing compatible versions (functions v4, admin v12)...
call npm install firebase-functions@^4.9.0 firebase-admin@^12.0.0 --save

if %errorlevel% neq 0 (
    echo [ERROR] npm install failed.
    pause
    exit /b 1
)

echo [SUCCESS] Dependencies updated.

REM Go back to project root to run firebase deploy
cd ..

echo Deploying functions...
call firebase deploy --only functions

pause
