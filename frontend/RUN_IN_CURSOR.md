# Run Flutter on a mobile device from Cursor (no Android Studio)

You can run the app on a **physical Android phone** or an **Android emulator** from Cursor, without installing Android Studio.

---

## Option 1: Physical Android phone (easiest for mobile)

No emulator, no Android Studio. Use your own phone.

### 1. On your Android phone

1. Open **Settings → About phone** and tap **Build number** 7 times to enable Developer options.
2. Go back to **Settings → Developer options** and turn on **USB debugging**.
3. Connect the phone to your PC with a USB cable.
4. When prompted on the phone, allow **USB debugging** for this computer.

### 2. On your PC (one-time)

- Install **Flutter SDK** and add `flutter\bin` to your PATH:  
  https://docs.flutter.dev/get-started/install/windows  
- Install **Android command-line tools** (so Flutter can talk to the device):
  - Download: https://developer.android.com/studio#command-tools  
  - Extract to a folder (e.g. `C:\Android\cmdline-tools`).
  - Set **ANDROID_HOME** to the SDK root (e.g. `C:\Android`).  
  - Add to PATH: `%ANDROID_HOME%\platform-tools` and `%ANDROID_HOME%\cmdline-tools\latest\bin` (or where `sdkmanager`/`adb` live).

### 3. Run from Cursor

Open **Terminal** in Cursor (`Ctrl+``), then:

```powershell
cd frontend
flutter pub get
flutter devices
```

Confirm your phone appears (e.g. "SM G991B (mobile)"). Then:

```powershell
flutter run
```

Flutter will install and run the app on your phone. Use **r** for hot reload, **R** for hot restart, **q** to quit.

### 4. Backend URL when using a real device

If the backend runs on your PC and the phone is on the **same Wi‑Fi**:

- In `frontend/lib/core/constants/api_constants.dart` set the base URL to your PC’s LAN IP, e.g. `http://192.168.1.100:3000/api` (replace with your PC’s IP).
- Or run the backend with `npm start` and use the IP shown by your Node server.

---

## Option 2: Android emulator (no Android Studio)

You can create and run an Android Virtual Device (AVD) using only command-line tools.

### 1. Install Android command-line tools

1. Download **Command line tools only** (Windows):  
   https://developer.android.com/studio#command-tools  
2. Extract to e.g. `C:\Android\cmdline-tools\latest` (so `sdkmanager.bat` is in that folder).
3. Set environment variables:
   - **ANDROID_HOME** = `C:\Android` (or your SDK root)
   - Add to **PATH**:  
     - `%ANDROID_HOME%\platform-tools`  
     - `%ANDROID_HOME%\cmdline-tools\latest\bin`

### 2. Install platform and system image

In PowerShell (or Cursor terminal):

```powershell
# Accept licenses
sdkmanager --sdk_root=%ANDROID_HOME% --licenses

# Install platform and system image (e.g. API 34)
sdkmanager --sdk_root=%ANDROID_HOME% "platform-tools"
sdkmanager --sdk_root=%ANDROID_HOME% "platforms;android-34"
sdkmanager --sdk_root=%ANDROID_HOME% "system-images;android-34;google_apis;x86_64"
```

(If `ANDROID_HOME` is not set in that terminal, replace `%ANDROID_HOME%` with your actual path, e.g. `C:\Android`.)

### 3. Create an AVD (emulator)

```powershell
avdmanager create avd -n Pixel_34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_6"
```

Use a different name/device if you prefer (e.g. `-n MyEmulator`).

### 4. Start the emulator

```powershell
emulator -avd Pixel_34
```

Leave this window open. When the emulator has booted, in **another** terminal in Cursor:

```powershell
cd frontend
flutter pub get
flutter devices
```

You should see the emulator in the list. Then:

```powershell
flutter run
```

### 5. Backend URL when using the emulator

The emulator treats your PC as `10.0.2.2`. In `frontend/lib/core/constants/api_constants.dart` use:

`http://10.0.2.2:3000/api`

---

## Quick reference (mobile)

| Goal                    | Command |
|-------------------------|--------|
| List devices/emulators | `flutter devices` |
| Run on connected device | `flutter run` |
| Run on specific device  | `flutter run -d <device-id>` |
| Check setup             | `flutter doctor -v` |

---

## Troubleshooting

- **Phone not listed in `flutter devices`**  
  - Install/update Android platform-tools (and add to PATH).  
  - Re-enable USB debugging, try another cable or USB port.  
  - On the phone, confirm “Allow USB debugging” when prompted.

- **Flutter says “no devices”**  
  - For a real device: connect it, unlock the screen, accept USB debugging.  
  - For emulator: start it first with `emulator -avd Pixel_34`, wait until it’s fully booted, then run `flutter run`.

- **ANDROID_HOME / sdkmanager not found**  
  Set ANDROID_HOME and add the Android `platform-tools` and `cmdline-tools\latest\bin` folders to your system PATH, then restart the terminal (or Cursor).
