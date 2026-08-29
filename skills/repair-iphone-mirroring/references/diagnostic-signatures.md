# Diagnostic signatures

Use several adjacent signals before assigning a failure layer. A single line is rarely sufficient.

## App-level signatures

| Signature | Interpretation |
| --- | --- |
| `Checking if Replicator has a device paired` followed by `noCompatiblePhone` | Prerequisites passed far enough to query relationship capability; inspect Replicator state. |
| `Tearing down the session due to: noCompatiblePhone` | The app rejected the current relationship as a compatible Mirroring phone. It is not by itself proof of Wi-Fi failure. |
| `Local Authentication is required` and `User interaction is required` | Stop automation and let the user authenticate. |
| `Touch ID is not available in closed clamshell mode` | Open the Mac or use the Mac login password. |
| `AppleWatch authentication failed` | Apple Watch fallback failed; it does not imply the iPhone connection failed. |
| `Unlock succeeded` then audio/video stream activation | The Mirroring connection is functioning. |

## Rapport discovery signatures

`MyiCloud`, `WiFiP2P`, `DeviceClose`, and strong RSSI together show that the Mac sees a nearby same-account device over Continuity discovery.

`Ignoring unsupported BLE device found` can coexist with successful discovery. Treat it as a capability-filter result unless surrounding logs also show missing discovery or transport.

`AcLv Disabled` can reflect current lock/access state. Do not infer account failure from it alone.

## Replicator relationship signatures

Healthy transport evidence includes:

- an established QUIC/TLS connection
- sent and received StateReplicator messages
- `isCloudPaired: true` for the target IDS device

A likely stuck relationship includes one or more of:

- `state: pairing` with `isPaired: true`, while the same relationship is listed under `Unpaired`
- `state: introduced` with `isPaired: false` after repeated attempts
- `No persona ID found for device`
- `Cannot pair with a device that is not known to the sync service`
- a selector permanently locked on `Pairing in progress`

When transport is healthy and these relationship contradictions persist after daemon restart, a targeted Replicator-state reset is justified after user approval.

## Known false leads

- CAML errors such as `No such class LKEventHandler` commonly arise while rendering the failure animation. Do not treat them as the root cause.
- `Privacy Stance: Not Eligible` is insufficiently specific on its own. Do not build a diagnosis around it.
- An active proxy, VPN, or network extension is not causal evidence. Require failed transport logs before changing it.
- Successful `devicectl` pairing proves developer-device access, not iPhone Mirroring compatibility.

## Success sequence

The exact numbering varies by OS build, but a healthy session commonly progresses through:

1. activate control stream
2. send startup configuration
3. request device unlock
4. validate local authorization
5. report `Unlock succeeded`
6. activate audio/video streams
7. report the device ready to be on screen

Verify that no immediate teardown follows this sequence.
