# Driving the server through the Comet KVM

The GL.iNet Comet (RM10) is a physical HDMI + USB KVM attached to the server.
It works in BIOS, boot menus, installers, the LUKS prompt, and a dead desktop.
The Mac-side client lives in `~/Developer/comet-kvm` (MCP server + skill).

## Endpoint

| Field | Value |
|---|---|
| Comet name (use in every tool call) | `server` |
| URL | `https://glkvm.local` (mDNS; LAN `192.168.4.85`, has also appeared as `.91`) |
| Web UI | `https://glkvm.local/#/`, user `admin` |
| Auth | Keychain service `com.openai.codex.omarchy.kvm-admin`, account `admin` |
| TLS | Custom CA `~/.config/comet-kvm/comet-ca.crt` ("GLKVM Local CA 2026", valid to 2036). Leaf cert on the device expires 2027-10-18, no auto-renewal |
| Config | `~/.config/comet-kvm/config.json` (no password inside; uses `password_command`) |
| Firmware | 1.10.0 release4 (recorded 2026-09-18, updated from 1.7.2 via the console updater) |
| Stream | Quality Ultra-high, transfer mode Direct (best latency, no audio). Session → Video in 1.10.x |
| ATX accessory | GL-ATXPC, wired, enabled (verified 2026-09-21). Short and long power presses work |

The Comet is on Wi-Fi (`192.168.4.85`, live). Its own Ethernet port was seen
once at `.91` and is normally down. Either way it is independent of the
server's NIC and stays reachable when the server's network or desktop dies.

## From an agent

**Claude Code**: the plugin is installed user-wide as `comet-kvm@skills-dir`
via the symlink `~/.claude/skills/comet-kvm` → `~/Developer/comet-kvm`. Tools
appear as `mcp__plugin_comet-kvm_comet-kvm__*`. Load the `comet-kvm` skill
for operating guidance.

**Codex**: installed as `comet-kvm@personal` from the implicit personal
marketplace (`~/.agents/plugins/marketplace.json`, root `~`, source
`~/plugins/comet-kvm` → the repo). Verified 2026-09-21: `codex plugin list`
shows it enabled and `codex exec` calling `list_comets` returned `["server"]`.
Codex runs a cached snapshot under `~/.codex/plugins/cache/personal/comet-kvm/`,
so after editing the repo, refresh it:

```sh
# Consult the currently installed plugin-creator skill for its supported
# cache refresh/reinstall flow; historical helper path is not portable.
```

Claude Code needs no refresh: its symlink points at the live repo.

**Any other MCP client** (Grok Bot, custom agents):

```json
{ "command": "uv",
  "args": ["run", "--directory", "/Users/bassimshahidy/Developer/comet-kvm", "--locked", "comet-kvm"] }
```

Tools: `list_comets`, `screenshot`, `type_text`, `press_keys`, `move_mouse`,
`click_mouse`, `scroll`, `power_state`, `press_atx`.

## Working loop

```
screenshot -> decide -> one short action -> screenshot
```

- Name `comet: "server"` on every call.
- Screenshot before typing. Focus follows the last click; newline submits.
- Text is US-layout ASCII. Check Caps Lock and layout before passwords.
- Prefer keyboard navigation in BIOS, boot menus, and terminals.
- Use `max_width: 3840` to read small terminal text.
- After an uncertain action, look before repeating. Input and power calls are
  never auto-replayed; a lost response may already have taken effect.

## Power

- Read `power_state` first. Known quirk on this unit: `power: "on"` with
  `leds.power: false` while the machine is clearly running. Trust video and
  `power` over the LED.
- Short press = the OS's own power-button behavior. Long press and reset cut
  writes and can corrupt the Btrfs volume. Prefer an orderly shutdown from a
  terminal when the OS responds.
- Don't use reset. Use a long press then a short press to power cycle.
- Wake-on-LAN is unavailable while the onboard NIC is unplugged
  (see `howto/server-access.md`).

## Virtual media

The Comet can mount an ISO as a bootable USB device (28.5 GB free as of
2026-09-19). The CachyOS install was done this way: ISO staged to the Comet,
SHA-256 verified, mounted, boot from the Comet USB entry in the ASUS boot menu.
Use the web UI for uploads; the MCP has no media tool.

## Known quirks (this unit, observed on 1.7.2; recheck on 1.10)

- Snapshot endpoint returns H.264 labeled as JPEG; the client decodes a direct
  video frame instead. Works, slightly slower.
- The TLS cert only covers `glkvm.local`. An IP URL fails verification.
- The API sometimes reports keyboard offline while input works. Test with a
  harmless key before declaring HID broken.
- Video can be stale after a boot transition. Take a second screenshot.
- Absolute mouse works on the desktop; some firmware screens need relative.

Deeper troubleshooting: `~/Developer/comet-kvm/skills/comet-kvm/troubleshooting.md`
and `~/Developer/comet-kvm/verification.md`.
