$SdkRoot = 'C:\Android\sdk'
New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null
$zip = "$env:TEMP\cmdline-tools.zip"
Write-Output "Downloading command-line tools..."
Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' -OutFile $zip -UseBasicParsing
Remove-Item -Recurse -Force "$env:TEMP\cmdlinetools" -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath "$env:TEMP\cmdlinetools" -Force
$found = Get-ChildItem -Path "$env:TEMP\cmdlinetools" -Directory | Where-Object { $_.Name -like 'cmdline*' } | Select-Object -First 1
if ($found -eq $null) { Write-Error 'Failed to find extracted cmdline-tools'; exit 1 }
$dest = Join-Path $SdkRoot 'cmdline-tools'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$latest = Join-Path $dest 'latest'
if (Test-Path $latest) { Remove-Item -Recurse -Force $latest }
Move-Item -Path $found.FullName -Destination $latest
Write-Output "Setting user environment variables..."
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT',$SdkRoot,'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME',$SdkRoot,'User')
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
$addPaths = @((Join-Path $SdkRoot 'platform-tools'), (Join-Path $SdkRoot 'cmdline-tools\latest\bin'))
foreach ($p in $addPaths) {
    if ($userPath -notlike "*$p*") { $userPath += ";" + $p }
}
[Environment]::SetEnvironmentVariable('Path',$userPath,'User')
# update current session
$env:ANDROID_SDK_ROOT = $SdkRoot
$env:ANDROID_HOME = $SdkRoot
$env:Path = (Join-Path $SdkRoot 'platform-tools') + ';' + (Join-Path $SdkRoot 'cmdline-tools\latest\bin') + ';' + $env:Path
$sdkManager = Join-Path $SdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
Write-Output "Installing packages (this may take a few minutes)..."
& $sdkManager --sdk_root="$SdkRoot" "platform-tools" "platforms;android-33" "build-tools;33.0.2" "extras;google;usb_driver"
Write-Output "Accepting licenses..."
$lic = "$env:TEMP\licenses_input.txt"
1..30 | ForEach-Object { 'y' } | Out-File -FilePath $lic -Encoding ASCII
Get-Content $lic | & $sdkManager --sdk_root="$SdkRoot" --licenses
Write-Output "Verifying adb"
if (Get-Command adb -ErrorAction SilentlyContinue) { adb version; adb devices } else { Write-Output "adb not found in PATH for current session." }
Write-Output "Done."