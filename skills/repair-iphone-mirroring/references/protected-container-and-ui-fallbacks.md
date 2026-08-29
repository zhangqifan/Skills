# Protected-container and UI fallbacks

Read this reference only when the normal shell or Computer Use path fails. These fallbacks do not broaden the user's authorization and do not remove the reset, Handoff, privacy-permission, credential, or destructive-action confirmation gates in `SKILL.md`.

## Protected Replicator container

### Decision gate

The Codex shell can sometimes `stat` known Replicator paths but cannot enumerate or hash them:

```text
find: .../group.com.apple.replicatord/replicatord: Operation not permitted
shasum: .../replicatord.sql: Operation not permitted
```

Do not infer database corruption or missing files from this TCC failure. Use this order:

1. Prefer full source access: explain that Full Disk Access applies to the actual host process and requires a host restart before verification. Obtain action-time confirmation before changing privacy permissions.
2. If the user explicitly chooses the previously successful Finder workflow, disclose that Finder can copy the protected items but cannot provide source SHA-256 evidence to the shell. This is a reduced-assurance fallback, not equivalent to matching source and backup manifests. The separate approval for resetting relationship state still applies.
3. Stop if Finder cannot show the complete top-level inventory, if any item is unknown, if a writer appears, or if the accessible backup fails validation.

Do not try to control Terminal through Computer Use when the environment forbids it. Do not invoke `CHSRemoteDeviceService` directly: an unentitled CLI can discover its Objective-C surface but its XPC operations fail and it is not a supported selector replacement.

### Finder fallback

Use Computer Use with Finder's bundle identifier `com.apple.finder` and re-read state after every action.

1. Create two uniquely timestamped mode-`0700` directories from the shell, using explicit validated paths:
   - backup data under `~/.codex/backups/iphone-mirroring/<timestamp>/data`
   - rollback set under `~/.Trash/iphone-mirroring-replicatord-rollback-<timestamp>`
2. In Finder, use Go to Folder to open exactly:

   ```text
   ~/Library/Group Containers/group.com.apple.replicatord/replicatord
   ```

3. Require Finder to show exactly the understood top-level set and status count: `records`, `replicatord.sql`, optional `replicatord.sql-shm`, optional `replicatord.sql-wal`, and optional `tmp`. Require `records` and `replicatord.sql`. Stop on any unknown item.
4. Turn Handoff off, quit iPhone Mirroring and System Settings, stop only the exact host `replicatord`, and require both no matching PID and no open SQL/WAL/SHM handle.
5. Re-read Finder's source inventory. Select every displayed item, copy it, open the backup `data` directory, and paste. Do not copy the parent group container.
6. Validate the accessible backup before moving the source:
   - exact expected top-level inventory, with no unknown item
   - the required items exist
   - regular-file sizes match the corresponding source `stat` values when those remain readable
   - a recursive backup manifest records relative path, type, size, symlink target, and SHA-256 for regular files
   - an ephemeral second copy of the database/WAL/SHM set returns `ok` from `PRAGMA quick_check`
7. Confirm again that no `replicatord` process or database handle appeared. Reopen the source in Finder and require the same names, count, visible sizes, and modification times seen before the copy. If anything changed, move the backup to Trash and stop.
8. Move the source items as one rollback set: select all, copy, open the pre-created rollback directory in Trash, then use Finder's Move Item Here command (`Option-Command-V`). Do not empty Trash.
9. Require Finder to show the rollback directory contains the complete expected set and the original source directory contains zero items. Corroborate absence with exact-path `test -e` checks for every known item.
10. Restore Handoff even if a later connection step fails. Reopen System Settings and continue with the uniquely named target.

Keep the formal backup until UI and log success are proven. If the user previously requested no retained backup, move the validated formal backup to Trash only after success; keep the rollback set unless the user explicitly requests permanent deletion.

## System Settings input fallback

Use this only when fresh state is readable but `sky.click` returns `native pipe closed` or repeatedly produces no state change.

1. Stop clicking. Target System Settings by bundle identifier `com.apple.systempreferences`.
2. Record whether `NSGlobalDomain AppleKeyboardUIMode` exists and its exact value. Explain the temporary change and obtain action-time confirmation for changing this local system setting.
3. Establish a cleanup/finally path, temporarily set `AppleKeyboardUIMode` to `3`, quit and reopen System Settings, and navigate to AirDrop & Continuity. Always restore the original value afterward; if the key was originally absent, delete only that exact key.
4. Use `Command-F` to find `iPhone Mirroring`, open the result, then clear and exit search so focus returns to the search field.
5. Use `Tab` and fresh accessibility state to locate the target pop-up. Do not hardcode a tab count: after each movement, verify the reported focused element. Current controls can include Go Back, the AirDrop menu, Manage, privacy information, Handoff, iPhone Widgets, Notifications & Live Activities, and the iPhone selector.
6. Press Space to open the selector. Re-read the menu, move one item at a time, and verify which entry is selected before committing with Return or Space. Do not guess menu order from flag emoji or device name.
7. Re-read the main page and require the pop-up value to equal the exact requested phone. If the user changes the app while automation is active, discard stale element indexes and re-read before acting.
8. Restore `AppleKeyboardUIMode` to its exact original state immediately after selection, including on failure.

If keyboard navigation cannot commit the selection, leave the selector visible and hand control to the user. Do not use private ChronoServices methods, edit opaque preference blobs, or claim that the target changed without fresh UI evidence.
