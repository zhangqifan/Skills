# Current Apple requirements

Verify the current requirements from Apple's live documentation before diagnosing beta or newly released operating systems:

- [iPhone Mirroring: Use your iPhone from your Mac](https://support.apple.com/en-us/120421)
- [Control your iPhone from your Mac](https://support.apple.com/guide/mac-help/control-your-iphone-from-your-mac-mchl444d53a6/mac)

At the time this skill was authored, Apple's baseline includes:

- a Mac with Apple silicon or the Apple T2 Security Chip running macOS Sequoia 15 or later
- an iPhone with a passcode running iOS 18 or later
- the same Apple Account with two-factor authentication on both devices
- Wi-Fi, Bluetooth, and Handoff enabled
- the iPhone locked, powered on, nearby, and not currently in use
- Internet Sharing, AirPlay, and Sidecar not active on the Mac
- availability in the current country or region
- only one Mac and one iPhone in an active Mirroring relationship at a time

Treat this list as a snapshot, not the source of truth. Re-open the Apple pages whenever the OS is a beta, the failure message mentions region or policy, or the requirements could have changed.

For multiple eligible phones, prefer Apple's supported selector in iPhone Mirroring settings. Establish a unique visible device name before selection when two phones are otherwise indistinguishable.

The selector location is versioned in Apple's current documentation:

- macOS Tahoe 26.4 or later: System Settings > General > AirDrop & Continuity
- earlier supported macOS versions: System Settings > Desktop & Dock, below iPhone Widgets

Before touching private Replicator state, prefer the supported iPhone Mirroring > Settings > `Revoke Access to [iPhone]` recovery action. Explain that it resets setup for that phone and also removes its notification authorization, then obtain confirmation before using it.

Apple's documented final fallback is to sign out of the Apple Account on both devices, restart, and sign back in. Treat that as a broad user-performed operation with separate confirmation. If instead proposing a local Replicator-state reset, disclose that it uses private implementation state and let the user choose between the two last-resort paths.
