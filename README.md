# Moonlight Remapper

A macOS menu bar utility that remaps **Left CMD to Left CTRL** when [Moonlight](https://moonlight-stream.org/) is the active (foreground) application.

This is useful for game streaming where you want macOS CMD shortcuts to map to Windows CTRL shortcuts (e.g., CMD+C becomes CTRL+C on the remote Windows machine).

## Features

- Remaps Left Command key to Left Control key
- Only active when Moonlight is the frontmost application
- Menu bar app with no Dock icon
- Toggle on/off from menu bar
- Launch at login support
- Visual status indicators

## Requirements

- macOS 14.0 (Sonoma) or later
- Moonlight game streaming client installed
- Accessibility permission

## Building

```bash
cd moonlight-remapper
chmod +x build-app.sh
./build-app.sh
```

This creates `MoonlightRemapper.app` in the project directory.

## Installation

1. Move `MoonlightRemapper.app` to `/Applications`
2. Open the app
3. Grant Accessibility permission when prompted (System Settings > Privacy & Security > Accessibility)
4. Enable remapping from the menu bar icon

## Usage

1. Click the keyboard icon in the menu bar
2. Toggle "Enable Remapping" on
3. Open Moonlight and start streaming
4. Left CMD will now act as Left CTRL while Moonlight is the active window

## Menu Bar Icons

- `keyboard.badge.ellipsis` - Remapping disabled
- `keyboard` - Remapping enabled, waiting for Moonlight
- `keyboard.fill` - Actively remapping (Moonlight is frontmost)

## Technical Details

The app uses:
- `CGEvent.tapCreate` to intercept keyboard events at the system level
- `NSWorkspace.didActivateApplicationNotification` + polling to detect frontmost app changes
- `flagsChanged` event type for modifier key detection
- Conditional remapping based on app bundle identifier (`com.moonlight-stream.Moonlight`)

## License

MIT
