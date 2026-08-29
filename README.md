# Skills

Public, installable agent skills for Codex and other agents that support the open Agent Skills format.

## Available skills

### repair-iphone-mirroring

Diagnoses and safely repairs stuck Apple iPhone Mirroring relationships on macOS. The workflow separates prerequisite, discovery, transport, relationship, selection, and authentication failures before considering a recoverable Replicator-state reset.

## Install with Codex

Ask Codex to install the skill from this repository:

```text
$skill-installer Install repair-iphone-mirroring from https://github.com/zhangqifan/Skills/tree/main/skills/repair-iphone-mirroring
```

The installer places the selected skill in the user's Codex skills directory. Restart Codex if the new skill does not appear immediately.

## Privacy

The repository contains no collected diagnostics, device identifiers, device names, account data, user paths, or repair backups.

The bundled diagnostic collector redacts UUIDs, connection identifiers, IP and MAC addresses, user paths, email addresses, telephone numbers, hostnames, and Apple account identifiers by default. Device display names remain visible locally because they are required to distinguish multiple eligible iPhones. Treat all diagnostic output as sensitive and do not publish it without reviewing it again.

`--include-identifiers` disables identifier redaction and is intended only for an explicitly approved local investigation.

## License

MIT
