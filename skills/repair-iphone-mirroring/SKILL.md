---
name: repair-iphone-mirroring
description: Diagnose and safely repair Apple iPhone Mirroring on macOS. Use for "Unable to Connect to iPhone", an AirDrop & Continuity selector stuck on "Pairing in progress", `noCompatiblePhone`, contradictory Replicator relationships, switching Mirroring between multiple iPhones, or verifying that a repaired session reaches unlock and audio/video readiness.
---

# Repair iPhone Mirroring

## Purpose

Separate discovery, transport, Replicator relationship, device selection, and local authentication failures. Prefer supported, reversible actions; reset only the task-owned Replicator state after evidence identifies it as the blocker.

## Operating rules

- Work read-only until the failure layer is identified.
- Identify the requested phone by a unique visible name, OS version, and—when available—device identifier. Treat an emoji or flag prefix as part of the name, not as an independent hardware identity.
- Preserve unrelated Continuity, iCloud, network, simulator, and developer-device state.
- Invoke the available Computer Use skill before operating System Settings, Finder, or iPhone Mirroring. Re-read fresh accessibility state after every UI action.
- If protected-container access or System Settings input fails, read [protected-container-and-ui-fallbacks.md](references/protected-container-and-ui-fallbacks.md) before changing privacy permissions or switching automation methods.
- Never enter a Mac password, iPhone passcode, or other credential. Stop at the authentication UI and hand control to the user.
- Do not disable VPNs, network extensions, firewalls, or security permissions without action-time confirmation. First prove whether transport is actually failing.
- Do not delete the whole `group.com.apple.replicatord` container. Reset only the contents of its `replicatord` child directory.
- Obtain action-time confirmation before restarting Continuity daemons, changing Handoff or keyboard-navigation settings, resetting relationship state, granting privacy permissions, or changing network/security configuration.
- Obtain action-time confirmation before collecting unredacted identifiers with `--include-identifiers`.
- Treat a reset as consequential: explain that it clears Mirroring, iPhone Widgets, and Live Activities relationship state, then obtain separate explicit approval.
- Move reset data to Trash; never empty Trash automatically.

## Workflow

### 1. Establish the target and baseline

Record:

- macOS version and build
- each candidate iPhone name, OS version, and availability
- the exact phone the user wants
- Wi-Fi, Bluetooth, Handoff, Apple Account, proximity, power, and lock state
- whether Internet Sharing, VPN, proxy, or a network extension is active

If two phones have the same display name, ask the user to rename the requested phone to a unique name before any repair. Confirm the OS version on the phone itself, then match that unique name in the Mac selector. A developer-device identifier can corroborate the mapping, but it does not prove Mirroring compatibility.

Read [current-apple-requirements.md](references/current-apple-requirements.md) and verify the live Apple Support page at execution time, especially on beta operating systems. Do not reuse a cached regional-availability or version assumption.

Run the read-only collector from the loaded skill directory when useful:

```bash
"<skill-directory>/scripts/collect-diagnostics.sh" --minutes 10
```

Resolve `<skill-directory>` from the selected `SKILL.md` location. Do not assume a particular user home or installation root.

Keep its output local unless the user explicitly asks to share it; device names and identifiers may be present.

The collector performs best-effort redaction of machine identifiers by default; device display names remain because they are needed for target selection. Use `--include-identifiers` only when an exact local device mapping requires them and after action-time confirmation. Treat all collector output as sensitive and never paste it into a report without reviewing and redacting it again.

Use `xcrun devicectl list devices` as evidence of USB/developer pairing only. Do not confuse it with iPhone Mirroring compatibility.

### 2. Inspect the UI and reproduce once

Open:

1. The version-appropriate iPhone selector:
   - macOS Tahoe 26.4 or later: System Settings > General > AirDrop & Continuity
   - earlier supported macOS versions: System Settings > Desktop & Dock, below iPhone Widgets
2. iPhone Mirroring

Capture the selected phone and whether the row is a usable pop-up or locked on `Pairing in progress`. Reproduce with `Try Again` once while collecting unified logs. Do not repeatedly click while the same state persists.

Read [diagnostic-signatures.md](references/diagnostic-signatures.md) before interpreting `iPhone Mirroring`, `replicatord`, or `rapportd` logs.

### 3. Classify the failure

Use evidence in this order:

1. **Prerequisite failure**: app prechecks identify Wi-Fi, Bluetooth, Handoff, Apple Account, OS support, policy, or proximity.
2. **Discovery failure**: `rapportd` cannot see the target at all.
3. **Transport failure**: Replicator cannot establish QUIC/TLS or exchange messages.
4. **Relationship failure**: transport works, but the app ends with `noCompatiblePhone`, relationship state is contradictory, or `personaID` is absent.
5. **Selection failure**: the requested phone is available, but the selector is locked to another phone.
6. **Authentication failure**: the session reaches local authorization but Touch ID, Apple Watch, or password authentication does not complete.

Do not blame a proxy or VPN merely because it is running. If Replicator exchanges StateReplicator messages over an established connection, the current blocker is above the transport layer.

### 4. Apply the repair ladder

Start with reversible supported actions:

1. Quit iPhone Mirroring and System Settings.
2. Explain that active AirDrop, Handoff, and related Continuity work may be interrupted, then obtain confirmation.
3. Restart only the current user's Continuity processes: `replicatord`, `rapportd`, `sharingd`, and `useractivityd`.
4. Verify each old PID exited; allow launchd to recreate the daemons, and record the replacement PIDs before continuing.
5. Reopen the selector and test the requested phone.
6. If the connection remains stuck and iPhone Mirroring > Settings offers `Revoke Access to [iPhone]`, explain that it resets Mirroring setup and removes that iPhone's notification authorization. Obtain separate confirmation, revoke access, then set up the uniquely named target again.
7. If the supported revoke/setup flow is unavailable or fails and relationship evidence remains inconsistent, present two explicit last-resort choices instead of silently choosing one:
   - Apple's documented Apple Account sign-out/restart/sign-in flow on both devices. This is supported but broad and disruptive; the user must perform it after reviewing iCloud data prompts.
   - The targeted local Replicator-state reset below. This is narrower and reversible when its backup checks pass, but it touches private implementation state and is not an Apple-supported public repair interface.
8. Proceed only after the user selects and confirms one of those paths.

Do not kill simulator daemons. Match both the current user ID and exact host path. First inspect the paths with `ps`; use the following known paths only when they match the current OS:

```bash
current_uid="$(id -u)"
pkill -TERM -U "$current_uid" -f '^/System/Library/PrivateFrameworks/ReplicatorCore\.framework/Support/replicatord$'
pkill -TERM -U "$current_uid" -f '^/usr/libexec/rapportd$'
pkill -TERM -U "$current_uid" -f '^/usr/libexec/sharingd$'
pkill -TERM -U "$current_uid" -f '^/System/Library/PrivateFrameworks/UserActivity\.framework/Agents/useractivityd$'
```

Do not assume a missing match means success; compare before/after PID and command-path evidence. If a path differs on the running OS, stop and investigate instead of broadening the match.

### 5. Reset Replicator relationship state

Use this only for a proven relationship or selection failure.

1. Explain the interruption, obtain confirmation, and turn Handoff off in System Settings. Re-read and summarize any warning before acting on it; continue only when its scope matches this repair.
2. Quit iPhone Mirroring and stop the exact host `replicatord` process. Verify that the old PID is gone and that no replacement process has the database open before copying it.
3. Resolve this directory exactly:

   ```text
   ~/Library/Group Containers/group.com.apple.replicatord/replicatord
   ```

4. Inventory the directory without mutation. The known set is `records`, `replicatord.sql`, `replicatord.sql-shm`, `replicatord.sql-wal`, and `tmp`; WAL, SHM, or `tmp` can be transient. Require `records` and `replicatord.sql`. If an unknown item exists, stop and investigate rather than performing a partial reset.
5. Create a uniquely timestamped, mode `0700` backup under `~/.codex/backups/iphone-mirroring/`, outside cloud-synced folders and the group container.
6. Capture a source manifest, confirm again that no matching `replicatord` PID or open database file exists, then copy exactly every existing item from the understood inventory. Preserve metadata. Record a relative-path, file-type, size, symlink-target, and SHA-256 manifest for regular files on both sides; require the manifests to match. Make an ephemeral second copy of the matched database/WAL/SHM set and run `PRAGMA quick_check` there so validation cannot mutate the formal backup.
7. Recheck the source manifest, matching PID, and open files after the copy. If the source changed or a writer appeared at any point, move the invalid snapshot to Trash and stop; do not use it as a backup.
8. If shell access is denied by macOS privacy controls, use the decision gate in [protected-container-and-ui-fallbacks.md](references/protected-container-and-ui-fallbacks.md). Prefer restoring full source/backup manifest access. Use the Finder fallback only when the user selects that reduced-assurance path; never silently equate a Finder copy with source/backup SHA equality.
9. Create a timestamped rollback-set folder in Trash and move only the successfully copied known source items into it. Verify every copied source item is absent and kept together; Finder may temporarily display stale rows whose URLs already point into `.Trash`.
10. Turn Handoff back on, quit and reopen System Settings, and launch iPhone Mirroring.

Never continue to removal if the backup is incomplete or database validation fails.

### 6. Select and connect the requested phone

Confirm that System Settings now shows the unique name of the requested phone and no longer says `Pairing in progress`. If the selector still cannot distinguish the phones, stop and resolve the mapping instead of guessing.

If Computer Use can read the selector but mouse actions return `native pipe closed` or make no state change, do not keep clicking. Follow the keyboard-navigation fallback in [protected-container-and-ui-fallbacks.md](references/protected-container-and-ui-fallbacks.md), restore the user's original keyboard-navigation preference afterward, and verify the selected value from fresh accessibility state.

Run `Try Again`, then `Continue`. If local authentication appears, hand control to the user. In closed-clamshell mode Touch ID can be unavailable; the user may need to enter the Mac login password or open the Mac.

### 7. Verify success

Require both UI and log evidence:

- the selector names the requested iPhone
- the main Mirroring window displays the remote device
- unlock succeeds
- control and audio/video streams activate
- the device reports ready to be on screen
- no immediate teardown follows

Report separately what was observed in UI, logs, and by the user. Do not claim credential entry or physical-device interaction that the agent did not perform.

### 8. Cleanup and rollback

- Keep the backup until the repaired session is verified.
- If the user requests cleanup after success, move the backup to Trash and report its location; do not empty Trash.
- Keep old source items in Trash as a short-term rollback point unless the user explicitly requests permanent deletion.
- To roll back, stop Handoff and `replicatord`, snapshot and validate the current new state into a separate timestamped recovery set, then restore the complete old coherent set and re-enable Handoff. Obtain confirmation before moving or replacing the new state. If the new-state snapshot cannot be validated, stop instead of making rollback one-way.

## Resources

- `scripts/collect-diagnostics.sh`: read-only system, device, process, state-file, and unified-log collector.
- `references/diagnostic-signatures.md`: mapping from relevant log signatures to failure layers and false leads.
- `references/current-apple-requirements.md`: execution-time compatibility and regional-availability verification checklist.
- `references/protected-container-and-ui-fallbacks.md`: Finder-based protected-container recovery and reversible keyboard navigation for macOS 27 UI failures.
