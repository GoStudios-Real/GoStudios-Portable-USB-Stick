# Builds goui-1.0.apk from goui\src using local SDK build-tools.
$ErrorActionPreference = "Stop"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$SDK = "C:\Users\RhysC\Android\Sdk"
$BT = Join-Path $SDK "build-tools\35.0.0"
$SRC = Join-Path $USBROOT "goui\src"
$BUILD = Join-Path $env:TEMP "goui-build"
$JAVA = (Get-Command javac).Source | Split-Path -Parent

Remove-Item $BUILD -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$BUILD\obj","$BUILD\apk" | Out-Null

# Stage resources: icon + wallpaper
New-Item -ItemType Directory -Force -Path "$SRC\res\drawable","$SRC\res\raw" | Out-Null
Copy-Item (Join-Path $USBROOT "goui\goui-icon.png") "$SRC\res\drawable\icon.png" -Force
Copy-Item (Join-Path $USBROOT "goui\wallpaper.png") "$SRC\res\raw\wallpaper.png" -Force

Write-Host "[1/6] aapt2 compile..."
$aaptOut = & "$BT\aapt2.exe" compile --dir "$SRC\res" -o "$BUILD\res.zip"
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed: $aaptOut" }

Write-Host "[2/6] aapt2 link..."
& "$BT\aapt2.exe" link -o "$BUILD\app-unsigned.apk" `
    -I "$SDK\platforms\android-36\android.jar" `
    --manifest "$SRC\AndroidManifest.xml" `
    -R "$BUILD\res.zip" `
    --auto-add-overlay `
    --java "$BUILD\gen"
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }

Write-Host "[3/6] javac..."
$sources = Get-ChildItem "$SRC\src\*.java","$BUILD\gen\*.java" -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if (-not $sources) { throw "No Java sources found" }
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& javac -source 11 -target 11 -nowarn -classpath "$SDK\platforms\android-36\android.jar" `
    -d "$BUILD\obj" $sources 2>&1 | ForEach-Object { "$_" }
$ErrorActionPreference = $prevEAP
if ($LASTEXITCODE -ne 0) { throw "javac failed" }

Write-Host "[4/6] d8 -> classes.dex..."
$classFiles = Get-ChildItem "$BUILD\obj\*.class" -Recurse | ForEach-Object { $_.FullName }
$d8args = "$BUILD\d8args.txt"
@("--release", "--lib", "$SDK\platforms\android-36\android.jar", "--output", "$BUILD\apk") + ($classFiles | ForEach-Object { "$_" }) | Set-Content $d8args -Encoding ASCII
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& java -Xmx1024M -cp "$BT\lib\d8.jar" com.android.tools.r8.D8 "@$d8args"
$ErrorActionPreference = $prevEAP
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }
if (-not (Test-Path "$BUILD\apk\classes.dex")) { throw "classes.dex not produced" }

Write-Host "[5/6] add dex + zipalign..."
Copy-Item "$BUILD\app-unsigned.apk" "$BUILD\app-dex.apk" -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$BUILD\app-dex.apk", "Update")
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$BUILD\apk\classes.dex", "classes.dex") | Out-Null
$zip.Dispose()
& "$BT\zipalign.exe" -f 4 "$BUILD\app-dex.apk" "$BUILD\app-aligned.apk"
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

# Keystore
$KS = "$BUILD\goui.keystore"
if (-not (Test-Path $KS)) {
    Write-Host "[6a] creating keystore..."
    & keytool -genkeypair -v -keystore $KS -alias goui -keyalg RSA -keysize 2048 `
        -validity 10000 -storepass gostudios -keypass gostudios `
        -dname "CN=GoStudios, OU=GoUI, O=GoStudios, C=US" | Out-Null
}

Write-Host "[6/6] signing..."
& cmd /c "`"$BT\apksigner.bat`" sign --ks `"$KS`" --ks-key-alias goui --ks-pass pass:gostudios --key-pass pass:gostudios --out `"$USBROOT\goui\goui-4.9.apk`" `"$BUILD\app-aligned.apk`""
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }
Copy-Item (Join-Path $USBROOT "goui\goui-4.9.apk") (Join-Path $USBROOT "goui\goui-1.0.apk") -Force

Write-Host "OK: goui\goui-4.9.apk (also goui-1.0.apk) built and signed."
