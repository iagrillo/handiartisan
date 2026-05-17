# Kill any Gradle or Java daemons that may be holding locks
Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "gradle" -Force -ErrorAction SilentlyContinue

# Clean Flutter build state
flutter clean

# Remove local build artifacts
Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue

# Remove Dart and Gradle metadata
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .gradle -ErrorAction SilentlyContinue

# Wipe global Gradle caches (robocopy trick ensures stubborn folders are cleared)
New-Item -ItemType Directory -Force $env:TEMP\empty | Out-Null
robocopy $env:TEMP\empty $env:USERPROFILE\.gradle\caches /MIR | Out-Null
robocopy $env:TEMP\empty $env:USERPROFILE\.gradle\wrapper\dists /MIR | Out-Null
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\wrapper\dists -ErrorAction SilentlyContinue

# Repair Flutter Pub cache and fetch dependencies
flutter pub cache repair
flutter pub get

# Finally, rebuild the release app bundle
flutter build appbundle --release
