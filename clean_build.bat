@echo off
echo Killing Gradle and Java processes...
taskkill /F /IM java.exe /T
taskkill /F /IM gradle.exe /T

echo Cleaning Flutter project...
flutter clean

echo Removing build folders...
rmdir /S /Q android\app\build
rmdir /S /Q android\build
rmdir /S /Q build

echo Wiping Gradle caches...
rmdir /S /Q "%USERPROFILE%\.gradle\caches"
rmdir /S /Q "%USERPROFILE%\.gradle\wrapper\dists"

echo Repairing Flutter Pub cache...
flutter pub cache repair

echo Fetching dependencies...
flutter pub get

echo Building release appbundle...
flutter build appbundle --release

echo Done!
pause
