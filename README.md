# GoStudios Portable USB Stick

A non-bootable portable Android 16 USB stick that runs Android in an emulator on any Windows PC.
Plug it in and Android 16 (with GoUI 4.9 as the system UI) auto-opens in fullscreen; unplug and it auto-closes.

## Contents
- `launch.ps1` / `launch.bat` — boots Android 16 + GoUI 4.9
- `create-avd.ps1` — (re)creates the AVD
- `setup.ps1` — installs SDK components to `D:\SDK`
- `build-goui.ps1` — rebuilds `goui\goui-4.9.apk`
- `watcher.ps1` / `install-watcher.ps1` — auto-open/close on plug/unplug
- `goui\` — GoUI 4.9 source + signed APK
- `apps\` — preinstalled gaming APKs (drop APKs here)

## First-time setup (on the host PC)
1. Run `setup.ps1` (installs emulator + Play Store image to `D:\SDK`).
2. Run `create-avd.ps1` (creates the Android 16 AVD).
3. Run `build-goui.ps1` if you changed GoUI source.
4. (Optional, as Administrator) Run `install-watcher.ps1` to auto-open on plug-in.

## Daily use
- Plug in the USB (labelled "GoStudios Portable USB Stick").
- `launch.bat` runs automatically (or via watcher) and opens Android 16 + GoUI 4.9 fullscreen.
- Unplug (or close the emulator window) → session closes and returns to desktop.

## GoUI 4.9 features
- GoStudios Account system (sign-in / create account)
- GoStudios Gaming Hub (GoStudios Picks + Web Apps: Xbox Cloud Gaming, PlayTree, GeForce NOW, Steam Link, YouTube, Discord)
- Google Play Store tab
- Multiple Home "Spots" (12 apps per spot, paged)
- GoStudios boot splash

## Requirements
- Windows 10/11, 8 GB RAM recommended, WHPX enabled
- ~4 GB free on the USB (NTFS, labelled "GoStudios Portable USB Stick")
- Host SDK at `C:\Users\<you>\Android\Sdk` (cmdline-tools, build-tools, platforms)

## Notes
- The USB is NTFS (FAT32/exFAT can't hold the 11+ char label).
- Play Store image enforces a 6 GB userdata partition; this stick uses a pre-created 2 GB sparse ext4 image to fit on the USB.
- On-screen keyboard is the stock Android IME.
