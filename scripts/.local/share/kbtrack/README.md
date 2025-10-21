# kbtrack

`kbtrack` is an automated battery-life tracker for the NuPhy Air75 V3 keyboard. It polls the Bluetooth Battery Service via CoreBluetooth, records connected time while the keyboard discharges, and stores per-cycle history so you can compare real-world battery life to the vendor claims.

## Components

- **Swift CLI (`kbtrack.swift`)** – lives in this directory and implements the Bluetooth reader, state machine, CLI commands, and logging.
- **Installer script (`~/.local/bin/install-kbtrack`)** – compiles `kbtrack.swift` with `swiftc`, links CoreBluetooth/Foundation, and drops the binary at `~/.local/bin/kbtrack`.
- **LaunchAgent (`scripts/Library/LaunchAgents/com.user.kbtrack.plist`)** – runs `kbtrack daemon` every 60 s after login so data is captured automatically.
- **Data directory (`~/Library/Application Support/kbtrack/`)** – holds `current.json` (active session), `sessions.json` (completed sessions), `samples.jsonl` (rolling per-minute telemetry), and `daemon.log` (per-cycle logs).

## Installation workflow

1. Ensure the dotfiles repo is stowed (`cd ~/dotfiles && stow scripts`) so the installer and LaunchAgent are symlinked into place.
2. Compile/install the CLI:
   ```bash
   ~/.local/bin/install-kbtrack
   ```
   This script verifies `swiftc`, compiles `kbtrack.swift`, and marks the binary executable.
3. Load (or reload) the LaunchAgent:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.kbtrack.plist
   ```
   macOS will now invoke `kbtrack daemon` once per minute.

## Runtime behaviour

- Sessions start when the keyboard is connected and ≥80 % battery, and time only accrues while connected.
- The daemon now tolerates transient failures (e.g. 0 % reads) by waiting for several consecutive misses before ending the session; legitimate stops still occur at <5 % battery or when charging is detected.
- `samples.jsonl` captures every poll (timestamp, percent, connection status) which powers smoothed discharge estimates and verbose diagnostics via `kbtrack status --verbose`.
- Standard commands:
  - `kbtrack status [--verbose]` – current metrics, overall + smoothed discharge rate, pending stop condition, recent samples.
  - `kbtrack history` – completed sessions with duration and stop reason.
  - `kbtrack reset` – force completion of the active session.

All files under `~/Library/Application Support/kbtrack/` can be deleted to reset tracking; the next daemon run will recreate them.
