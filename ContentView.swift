
/*****************************************************************
*     File name:                        ContentView.swift
*     Music Player Skin App
*     Harlee Ramos  July 2025
*     Description This file defines the main SwiftUI view for the music player application,
    handling UI layout, playback controls, and interaction with audio files.
 *******************************************************************************************************/

import SwiftUI
import AppKit
import AVFoundation // Provides classes for audio playback, such as AVAudioPlayer.
import Foundation
import UniformTypeIdentifiers // Used for specifying file types (e.g., UTType.mp3).
import ImageIO // Used for extracting image data, specifically for album artwork.

/// A delegate class for `AVAudioPlayer` that handles the `audioPlayerDidFinishPlaying` event.
/// This allows for custom actions (like playing the next song) when a track completes.
class AVAudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
    /// A closure to be executed when the audio playback successfully finishes.
    let onFinish: () -> Void

    /// Initializes the delegate with a completion handler.
    /// - Parameter onFinish: A closure that will be called when the audio player finishes playing successfully.
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    /// Called when an audio player finishes playing a sound.
    /// - Parameters:
    ///   - player: The audio player that finished playing.
    ///   - flag: `true` if the playback finished successfully, `false` otherwise.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            onFinish()
        }
    }
}

// MARK: - Custom NSView for Window Dragging
/// `DraggableArea` is a SwiftUI `NSViewRepresentable` that provides a transparent overlay.
/// This overlay makes the entire background of the window draggable, enabling users to move
/// the window by clicking and dragging anywhere on its background.
struct DraggableArea: NSViewRepresentable {
    /// Creates and configures the `NSView` for the draggable area.
    /// It defers enabling `isMovableByWindowBackground` until the window is available,
    /// ensuring the property is set on the correct window instance.
    /// - Parameter context: The context for creating the view.
    /// - Returns: An `NSView` instance configured for window dragging.
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        // Defer setting `isMovableByWindowBackground` to the main queue to ensure
        // the view has been added to a window hierarchy and the window object is available.
        DispatchQueue.main.async {
            view.window?.isMovableByWindowBackground = true
        }
        return view
    }

    /// Updates the `NSView`. This method is intentionally left empty as the dragging
    /// behavior is configured once during view creation and does not require updates.
    /// - Parameters:
    ///   - nsView: The `NSView` instance to be updated.
    ///   - context: The context for updating the view.
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Track Model
/// `Song` is a simple structure that represents a music track.
/// It holds essential information about a song, including its title,
/// the artist's name, and an optional `NSImage` for album artwork.
struct Song: Identifiable {
    let id = UUID() // Unique identifier for SwiftUI list iteration.
    var title: String
    var artistName: String
    var artwork: NSImage?
}

// MARK: - Main View
/// `ContentView` is the primary SwiftUI view for the music player application.
/// It constructs the user interface, manages the playback state, and handles user interactions.
struct ContentView: View {
    // MARK: - State Variables
    @State private var backgroundURL: URL? = nil // Stores the URL of the selected static background image.
    @State private var isPlaying = false // Boolean that tracks the current playback state (playing/paused).
    @State private var currentTrack: Song? = nil // Holds the metadata (title, artist, artwork) of the currently playing song.
    @State private var musicFiles: [URL] = [] // An array of URLs pointing to the music files loaded into the player.
    @State private var audioPlayer: AVAudioPlayer? // The instance of `AVAudioPlayer` responsible for audio playback.
    @State private var currentTrackIndex: Int = 0 // The index of the current song within the `musicFiles` array.
    @State private var audioDelegate = AVAudioPlayerDelegateHandler(onFinish: {}) // Custom delegate for handling `AVAudioPlayer` events, like song completion.
    @State private var isPinned = false // Controls whether the application window is always on top of other windows.
    @State private var isLooping = false // Determines if the current song should repeat indefinitely.

    // MARK: - View Body
    /// The `body` property defines the layout and appearance of the `ContentView`.
    var body: some View {
        GeometryReader { geometry in // Provides access to the dimensions of the parent view.
            let w = geometry.size.width // Shorthand for the available width.
            let h = geometry.size.height // Shorthand for the available height.

            ScrollView { // Enables vertical scrolling if the content exceeds the viewable area.
                ZStack { // Arranges views along the Z-axis, stacking them from back to front.
                    // Background Image Display
                    // Displays the selected background image, resizing it to fit the view.
                    if let url = backgroundURL, let img = NSImage(contentsOf: url) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .id(url) // Forces SwiftUI to re-render the image if the URL changes.
                            .frame(width: w, height: h)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        // Displays a clear background if no image is selected.
                        Color.clear
                            .frame(width: w, height: h)
                    }

                    VStack(alignment: .leading, spacing: 0) { // Vertical stack for arranging UI elements from top to bottom.
                        // Window Control Buttons (Close, Minimize, Pin)
                        HStack(spacing: w * 0.012) { // Horizontal stack for grouping window control buttons.
                            // Close Button: Terminates the application.
                            Button(action: { NSApp.terminate(nil) }) {
                                Image("CloseIcon")
                                    .resizable()
                                    .frame(width: w * 0.025, height: w * 0.025) // Sizes the close icon.
                            }

                            // Minimize Button: Minimizes the application's first window.
                            Button(action: {
                                NSApp.windows.first?.miniaturize(nil)
                            }) {
                                Image("MinimizeIcon")
                                    .resizable()
                                    .frame(width: w * 0.025, height: w * 0.025) // Sizes the minimize icon.
                            }

                            // Pin Button: Toggles the window's "always on top" state.
                            Button(action: {
                                if let window = NSApp.windows.first {
                                    isPinned.toggle() // Toggles the pinned state.
                                    // Sets the window level to floating (always on top) or normal.
                                    window.level = isPinned ? .floating : .normal
                                }
                            }) {
                                Image("PinIcon")
                                    .resizable()
                                    .frame(width: w * 0.025, height: w * 0.025) // Sizes the pin icon.
                                    .opacity(isPinned ? 1.0 : 0.5) // Changes opacity to indicate pinned state.
                                    .shadow(radius: w * 0.01) // Adds a subtle shadow.
                            }
                        }
                        .frame(maxWidth: .infinity) // Centers the buttons horizontally.
                        .padding(.top, 0) // Adjusts top padding to position buttons higher.

                        // Icon Button: Choose Background
                        // Opens an `NSOpenPanel` to allow the user to select an image file for the background.
                        Button(action: {
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic] // Specifies allowed image file types.
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let url = panel.url {
                                backgroundURL = url // Updates the background URL if a file is selected.
                            }
                        }) {
                            Image("background_icon")
                                .resizable()
                                .frame(width: w * 0.065, height: w * 0.065)
                                .shadow(radius: w * 0.01)
                        }
                        .padding(.bottom, h * 0.01)

                        // Icon Button: Load Music Folder
                        // Opens an `NSOpenPanel` to allow the user to select a directory containing music files.
                        Button(action: {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false // Prevents selection of individual files.
                            panel.canChooseDirectories = true // Allows selection of directories.
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let selectedURL = panel.url {
                                do {
                                    let fileManager = FileManager.default // Accesses the default file manager.
                                    // Retrieves all audio files (MP3, M4A) from the selected directory.
                                    let audioFiles = try fileManager.contentsOfDirectory(at: selectedURL, includingPropertiesForKeys: nil)
                                        .filter { $0.pathExtension.lowercased() == "mp3" || $0.pathExtension.lowercased() == "m4a" }
                                    musicFiles = audioFiles // Updates the list of playable music files.
                                    if let first = audioFiles.first {
                                        // Sets the initial current track information and starts playback.
                                        currentTrack = Song(title: first.deletingPathExtension().lastPathComponent, artistName: "Unknown", artwork: nil)
                                        currentTrackIndex = 0 // Resets to the first track in the new list.
                                        playTrack(at: currentTrackIndex) // Initiates playback of the first track.
                                    }
                                } catch {
                                    print("Error loading music files: \(error.localizedDescription)") // Logs any errors during file loading.
                                }
                            }
                        }) {
                            Image("folder_icon")
                                .resizable()
                                .frame(width: w * 0.065, height: w * 0.065)
                                .shadow(radius: w * 0.01)
                        }
                        .padding(.bottom, h * 0.01)

                        Spacer() // Pushes content to the top, allowing the following ZStack to align to the bottom.

                        // Artwork and Track Info Display
                        // Shows the album artwork (or a placeholder) and the current track's title.
                        ZStack {
                            VStack(spacing: 5) {
                                if let artwork = currentTrack?.artwork {
                                    Image(nsImage: artwork)
                                        .resizable()
                                        .frame(width: w * 0.22, height: w * 0.22)
                                        .shadow(radius: w * 0.015)
                                } else {
                                    Image(systemName: "music.note") // Placeholder icon if no artwork is available.
                                        .resizable()
                                        .frame(width: w * 0.09, height: w * 0.09)
                                        .shadow(radius: w * 0.015)
                                }
                                Text(currentTrack?.title ?? "No Track") // Displays the track title or "No Track".
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.top, h * 0.4)
                            .padding(.trailing, w * 0.4)
                        }

                        // Playback Controls (Previous, Play/Pause, Next, Loop)
                        ZStack {
                            VStack {
                                Spacer() // Pushes the controls to the bottom of the VStack.
                                HStack(spacing: w * 0.04) {
                                    // Previous Track Button
                                    Button(action: { skipBackward() }) {
                                        Image("previous")
                                            .resizable()
                                            .renderingMode(.original) // Ensures the image retains its original colors.
                                            .frame(width: w * 0.09, height: w * 0.09)
                                            .shadow(radius: w * 0.01)
                                    }
                                    
                                    // Play/Pause Button (toggles between play and pause icons)
                                    ZStack {
                                        if !isPlaying {
                                            Button(action: { togglePlayPause() }) {
                                                Image("play")
                                                    .resizable()
                                                    .renderingMode(.original)
                                                    .frame(width: w * 0.07, height: w * 0.07)
                                                    .shadow(radius: w * 0.01)
                                            }
                                            .transition(.opacity) // Smooth fade transition for icon change.
                                        }
                                        if isPlaying {
                                            Button(action: { togglePlayPause() }) {
                                                Image("pause")
                                                    .resizable()
                                                    .renderingMode(.original)
                                                    .frame(width: w * 0.07, height: w * 0.07)
                                                    .shadow(radius: w * 0.01)
                                            }
                                            .transition(.opacity) // Smooth fade transition for icon change.
                                        }
                                    }
                                    .animation(.easeInOut, value: isPlaying) // Applies animation when `isPlaying` changes.

                                    // Next Track Button
                                    Button(action: { skipForward() }) {
                                        Image("next")
                                            .resizable()
                                            .renderingMode(.original)
                                            .frame(width: w * 0.07, height: w * 0.07)
                                            .shadow(radius: w * 0.01)
                                    }
                                    
                                    // Loop Button: Toggles single-track looping.
                                    Button(action: {
                                        isLooping.toggle()
                                    }) {
                                        Image(systemName: "repeat.1") // System icon for repeating a single item.
                                            .resizable()
                                            .frame(width: w * 0.07, height: w * 0.07)
                                            .opacity(isLooping ? 1.0 : 0.4) // Changes opacity to indicate loop state.
                                            .shadow(radius: w * 0.01)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, h * 0.05)
                                .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: geometry.size.height) // Ensures the ZStack takes up the full height.
                .overlay( // Overlays the `DraggableArea` on top of the entire content.
                    DraggableArea()
                        .ignoresSafeArea() // Extends the draggable area to the safe area insets.
                )
            }
            .onAppear {
                // When the view appears, if music files are already loaded (e.g., from a previous session),
                // it starts playing the current track.
                if !musicFiles.isEmpty {
                    playTrack(at: currentTrackIndex)
                }
            }
        }
    }
        
    // MARK: - Playback Functions

    /// Plays the track at the specified index from the `musicFiles` array.
    /// - Parameter index: The zero-based index of the track to play.
    func playTrack(at index: Int) {
        // Ensures the provided index is within the bounds of the `musicFiles` array.
        guard musicFiles.indices.contains(index) else { return }

        let url = musicFiles[index] // Gets the URL of the track to be played.

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url) // Initializes `AVAudioPlayer` with the track's URL.
            let title = url.deletingPathExtension().lastPathComponent // Extracts the song title from the file name.
            
            // Asynchronously extracts album artwork from the audio file.
            Task {
                let artwork = await extractArtwork(from: url)
                // Updates the UI on the main thread after artwork extraction.
                DispatchQueue.main.async {
                    currentTrack = Song(
                        title: title,
                        artistName: "Unknown", // Placeholder: ideally, this would be extracted from audio metadata.
                        artwork: artwork
                    )
                }
            }

            // Sets up the `AVAudioPlayerDelegateHandler` to handle playback completion.
            // When a song finishes, it either loops the current track or plays the next one.
            audioDelegate = AVAudioPlayerDelegateHandler(onFinish: {
                if isLooping {
                    playTrack(at: currentTrackIndex) // Replays the current track if looping is enabled.
                } else {
                    skipForward() // Moves to the next track if looping is off.
                }
            })
            audioPlayer?.delegate = audioDelegate // Assigns the custom delegate to the audio player.

            audioPlayer?.play() // Starts audio playback.
            isPlaying = true // Updates the playback state to `true`.
        } catch {
            print("Failed to play track: \(error.localizedDescription)") // Logs any errors that occur during playback.
        }
    }

    /// Toggles the play/pause state of the current track.
    /// If the audio is playing, it pauses it; if paused, it resumes playback.
    func togglePlayPause() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause() // Pauses playback if currently playing.
                isPlaying = false
            } else {
                player.play() // Resumes playback if currently paused.
                isPlaying = true
            }
        }
    }

    /// Skips to the next track in the `musicFiles` playlist.
    /// If currently playing, it stops the current track before moving to the next.
    func skipForward() {
        audioPlayer?.stop() // Stops the currently playing track.
        guard !musicFiles.isEmpty else { return } // Exits if there are no music files loaded.
        // Calculates the index of the next track, cycling back to the beginning if at the end.
        currentTrackIndex = (currentTrackIndex + 1) % musicFiles.count
        playTrack(at: currentTrackIndex) // Plays the new track.
    }

    /// Skips to the previous track in the `musicFiles` playlist.
    /// If currently playing, it stops the current track before moving to the previous.
    func skipBackward() {
        audioPlayer?.stop() // Stops the currently playing track.
        guard !musicFiles.isEmpty else { return } // Exits if there are no music files loaded.
        // Calculates the index of the previous track, handling wrap-around for the start of the list.
        currentTrackIndex = (currentTrackIndex - 1 + musicFiles.count) % musicFiles.count
        playTrack(at: currentTrackIndex) // Plays the new track.
    }

    /// Extracts album artwork from an audio file URL asynchronously.
    /// It uses `AVURLAsset` to access metadata and retrieve the artwork.
    /// - Parameter url: The `URL` of the audio file.
    /// - Returns: An `NSImage` representing the artwork, or `nil` if no artwork is found or an error occurs.
    func extractArtwork(from url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url) // Creates an `AVURLAsset` from the audio file URL.
        do {
            // Loads common metadata keys where artwork is typically stored.
            let metadata = try await asset.load(.commonMetadata)
            // Finds the metadata item specifically for artwork.
            if let artworkItem = metadata.first(where: { $0.commonKey?.rawValue == "artwork" }) {
                guard let data = try await artworkItem.load(.dataValue) else { return nil } // Loads the artwork data.
                return NSImage(data: data) // Creates an `NSImage` from the loaded data.
            }
        } catch {
            print("Failed to load artwork: \(error.localizedDescription)") // Logs any errors during artwork extraction.
        }
        return nil // Returns `nil` if no artwork is found or an error occurs.
    }
}
    
// MARK: - Custom Window Configuration
/// `WindowAccessor` is a SwiftUI `NSViewRepresentable` that provides access to the application's
/// main `NSWindow` to apply custom configurations, such as making the title bar transparent,
/// hiding default window controls, and setting a fixed window size.
struct WindowAccessor: NSViewRepresentable {
    /// Creates and configures an `NSView`. This method is used to gain access to the `NSWindow`
    /// that contains the SwiftUI view hierarchy. All window modifications are deferred to the
    /// main queue to ensure the window is fully initialized and available.
    /// - Parameter context: The context for creating the view.
    /// - Returns: An `NSView` instance (primarily used to get a reference to its `window`).
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Defer window modifications to the main queue to ensure the window is ready
        // and accessible from the NSApp.windows array.
        DispatchQueue.main.async {
            if let window = NSApp.windows.first { // Retrieves the first (main) window of the application.
                window.titlebarAppearsTransparent = true // Makes the window's title bar transparent.
                window.titleVisibility = .hidden // Hides the window title text.
                
                // Removes the title bar separator line. This is handled differently
                // for macOS versions 13.0 and above.
                if #available(macOS 13.0, *) {
                    window.titlebarSeparatorStyle = .none
                } else {
                    // Fallback for older macOS versions: hides any toolbar baseline separator if present.
                    window.toolbar?.showsBaselineSeparator = false
                }
                
                window.styleMask.insert(.fullSizeContentView) // Allows the content view to extend into the title bar area.
                window.styleMask.remove(.titled) // Removes the default window title bar, making it borderless.
                window.toolbar = nil // Removes any existing toolbar from the window.
                
                // Hides the standard macOS traffic light buttons (close, minimize, zoom)
                // as custom controls are provided in the `ContentView`.
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                window.isOpaque = true // Ensures the window's content is drawn opaquely, preventing issues with transparency.
                window.backgroundColor = .clear // Sets the window's background to clear, allowing custom backgrounds to show.
                window.hasShadow = false // Disables the default system window shadow.
                window.setContentSize(NSSize(width: 230, height: 400)) // Sets a fixed initial size for the window.
                window.makeKeyAndOrderFront(nil) // Makes the window the key window and brings it to the front.
                // The vibrancy background effect in the title bar area is implicitly removed by
                // setting `titlebarAppearsTransparent` and `backgroundColor = .clear`.
            }
        }
        return view
    }

    /// Updates the `NSView`. This method is intentionally empty because the window
    /// configuration is a one-time setup and does not require periodic updates.
    /// - Parameters:
    ///   - nsView: The `NSView` instance to be updated.
    ///   - context: The context for updating the view.
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - App Entry Point
/// `Music_Player_SkinApp` is the main entry point for the Music Player Skin application.
/// It defines the application's structure and the initial window that will be displayed.
@main // Marks this struct as the application's entry point.
struct Music_Player_SkinApp: App {
    /// The `body` property defines the application's scene hierarchy.
    var body: some Scene {
        WindowGroup { // Defines a window group, which manages one or more windows.
            ZStack { // Lays out `ContentView` and `WindowAccessor` on top of each other.
                ContentView() // The main user interface of the music player.
                WindowAccessor() // A helper view to access and customize the underlying `NSWindow`.
            }
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle()) // Applies a unified toolbar style, if applicable (though custom controls are used).
    }
}

