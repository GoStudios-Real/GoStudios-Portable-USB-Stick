# Builds cloudgaming/cloudgaming.apk (GoCloud Gaming)
$ErrorActionPreference = "Continue"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$SRC = Join-Path $USBROOT "cloudgaming\src"
$BT = "C:\Users\RhysC\Android\Sdk\build-tools\35.0.0"
$PLAT = "C:\Users\RhysC\Android\Sdk\platforms\android-36"
$BUILD = Join-Path $env:TEMP "cloudgaming-build"
$KS = Join-Path $BUILD "cloudgaming.keystore"

if (Test-Path $BUILD) { Remove-Item $BUILD -Recurse -Force }
New-Item -ItemType Directory -Force -Path $BUILD | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BUILD "gen") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BUILD "obj") | Out-Null

# 1. aapt2 compile resources
& (Join-Path $BT "aapt2.exe") compile --dir (Join-Path $SRC "res") -o (Join-Path $BUILD "res.zip") 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }
Write-Host "[1/6] aapt2 compile done"

# 2. aapt2 link
$manifest = Join-Path $SRC "AndroidManifest.xml"
& (Join-Path $BT "aapt2.exe") link -o (Join-Path $BUILD "app.apk") --manifest $manifest -I (Join-Path $PLAT "android.jar") --java (Join-Path $BUILD "gen") (Join-Path $BUILD "res.zip") 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }
Write-Host "[2/6] aapt2 link done"

# 3. javac
$cp = (Join-Path $PLAT "android.jar") + ";" + (Join-Path $BUILD "gen")
$srcFiles = @()
$srcFiles += Get-ChildItem -Path (Join-Path $SRC "com") -Recurse -Filter *.java | ForEach-Object { $_.FullName }
$srcFiles += Get-ChildItem -Path (Join-Path $BUILD "gen") -Recurse -Filter *.java | ForEach-Object { $_.FullName }
& javac -source 11 -target 11 -nowarn -cp $cp -d (Join-Path $BUILD "obj") $srcFiles 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "javac failed" }
Write-Host "[3/6] javac done"

# 4. d8
$argfile = Join-Path $BUILD "d8args.txt"
$objDir = Join-Path $BUILD "obj"
$jarPath = Join-Path $BT "lib\d8.jar"
"--output" | Set-Content $argfile
$BUILD | Add-Content $argfile
"--lib" | Add-Content $argfile
(Join-Path $PLAT "android.jar") | Add-Content $argfile
Get-ChildItem $objDir -Recurse -Filter *.class | ForEach-Object { $_.FullName | Add-Content $argfile }
& java -Xmx1024M -cp $jarPath com.android.tools.r8.D8 "@$argfile" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }
Write-Host "[4/6] d8 done"

# 5. add dex + zipalign
Copy-Item (Join-Path $BUILD "app.apk") (Join-Path $BUILD "app-with-dex.apk") -Force
& (Join-Path $BT "zipalign.exe") -f 4 (Join-Path $BUILD "app-with-dex.apk") (Join-Path $BUILD "app-aligned.apk") 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }
Write-Host "[5/6] zipalign done"

# 6. keystore + sign
if (-not (Test-Path $KS)) {
    & keytool -genkeypair -v -keystore $KS -alias cloud -keyalg RSA -keysize 2048 -validity 10000 -storepass gostudios -keypass gostudios -dname "CN=GoStudios, OU=Cloud, O=GoStudios, C=US" 2>&1 | Out-Null
}
& (Join-Path $BT "apksigner.bat") sign --ks $KS --ks-key-alias cloud --ks-pass pass:gostudios --key-pass pass:gostudios --v1-signing-enabled true --v2-signing-enabled true --out (Join-Path $USBROOT "cloudgaming\cloudgaming.apk") (Join-Path $BUILD "app-aligned.apk") 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }
Write-Host "[6/6] signed: cloudgaming\cloudgaming.apk"