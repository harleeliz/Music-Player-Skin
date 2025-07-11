# Music Player Skin App

A lightweight macOS music player with a customizable background, simple playback controls, and a sleek, borderless interface built in SwiftUI.

---

## Features

- **Custom Backgrounds**: Choose any static image (`.png`, `.jpeg`, `.tiff`, `.heic`) as the window background.
- **Playback Controls**: Play, pause, skip forward, skip backward, and toggle single-track looping.
- **Folder-Based Music Loading**: Select a directory to load all MP3 and M4A files at once.
- **Borderless Window**: Transparent, frameless window with draggable background.
- **Album Artwork Support**: Extracts embedded cover art from audio file metadata *If the file have.

---

## Requirements

- **macOS** – 12.0 or later  
- **Xcode** – 14.0 or later  
- **Swift** – 5.6 or later  




---

## Background requirements
- **Extension (`.png`, `.jpeg`, `.tiff`, `.heic`) .
- **Size 230 x 400 px - or similar ratio.
---



## Installation

```bash
git clone https://github.com/yourusername/music-player-skin.git
cd music-player-skin
open Music_Player_Skin.xcodeproj
# Then press ⌘R in Xcode to build and run
```

---

## Usage

1. **Load Music Folder**  
   Click the folder icon and select a directory containing your `.mp3` or `.m4a` tracks. Playback starts automatically on the first track.

2. **Playback Controls**  
   - **⏮️ Previous** – Go to the previous track (stops current track before switching).  
   - **▶️ Play/Pause** – Toggle playback state.  
   - **⏭️ Next** – Skip to the next track (stops current track before switching).  
   - **🔁 Loop** – Repeat the current track indefinitely.

3. **Change Background**  
   Click the background icon and choose a static image file to update the window’s background.

4. **Custom Window Buttons**  
   - **Close** – Quit the application.  
   - **Minimize** – Minimize the window.  
   - **Pin** – Toggle “always on top” mode.

---

## Customization

- **Window Size**: Adjust the `window.setContentSize` values in `WindowAccessor` to change the default dimensions.  
- **Artwork Extraction**: Review the `extractArtwork(from:)` method to adjust metadata keys or fallback artwork behavior.  
- **Supported Formats**: Extend the `NSOpenPanel`’s `allowedContentTypes` to support additional static image formats if needed.

---

## Contributing

Contributions, issues, and feature requests are welcome! Please follow these steps:

1. Fork the project.  
2. Create your feature branch (`git checkout -b feature-name`).  
3. Commit your changes (`git commit -m 'Add feature'`).  
4. Push to the branch (`git push origin feature-name`).  
5. Open a Pull Request.
6. Let me know.

