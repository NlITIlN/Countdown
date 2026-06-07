$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found in PATH." -ForegroundColor Red
    Write-Host "Install: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}

if (-not (Test-Path "android")) {
    Write-Host "Creating Android, iOS, Windows platforms..."
    flutter create . --org com.countdown --project-name countdown --platforms=android,ios,windows
}
elseif (-not (Test-Path "windows")) {
    Write-Host "Adding Windows desktop support..."
    flutter create . --org com.countdown --project-name countdown --platforms=windows
}

Write-Host "Running flutter pub get..."
flutter pub get

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "Run order:" -ForegroundColor Cyan
Write-Host '  1. Windows:  flutter run -d windows'
Write-Host '  2. Android:  start emulator, then: flutter run'
Write-Host '  3. iOS:      Mac with Xcode only'
Write-Host ""
Write-Host '  Devices:   flutter devices'
