# Theo Linux workflow findings for your existing homelab

Reviewed 30 September 2026

## Recommendation

Start with the CachyOS/Niri 5700G server you already have. Use your chosen T3 Code desktop app plus T3 Connect for remote agent work, alongside your preferred CLI/herdr workflows. Keep the Mac as your entry point and local-development machine, Tailscale plus SSH for routine host access, and Comet for recovery. These videos do not establish that you need new hardware, a distro change, or a filesystem migration.

Keep the planned stable infrastructure/NAS separate from hackable development and disposable workers. Choosing storage for reliable services and choosing storage for repeated package installs are different decisions.

## Caption coverage

I reviewed the complete available timestamped caption bodies for all three videos, including their closing sections. This was caption-based research, not full audio/video playback or an independently validated official subtitle download.

| Video | Source read | Available coverage | Qualification |
| --- | --- | --- | --- |
| [Why I’m moving to Linux for real](https://www.youtube.com/watch?v=9tGrhrVKCrE) | [transcribe](https://www.usetranscribe.io/yt/9tGrhrVKCrE/moving-to-linux) | 0:00 through the 37:30 closing section; 44 timestamp anchors; player 38:05 | Full displayed transcript body; automated transcription provenance not independently verified |
| [I’m done with terminals](https://www.youtube.com/watch?v=dLhcLqoff6k) | [Arcmira](https://arcmira.com/watch?v=dLhcLqoff6k) | 0:00 through the 30:50 closing section; 47 timestamp anchors | Arcmira labels this public YouTube captions; 6,695 source-labeled words |
| [MacOS Is Making Your Mac Slow](https://www.youtube.com/watch?v=4wVNFaFDIn8) | [Arcmira](https://arcmira.com/watch?v=4wVNFaFDIn8) | 0:00 through the 31:18 closing section; 45 timestamped paragraphs; embedded player 31:48 | Full public caption body; mirror title is Your Mac is slowing you down a rant about file systems |

Timestamps identify coarse caption sections. Captions contain recognizable transcription errors, especially tool names and decimal benchmark values. Exact ambiguous numbers should be checked against the video's chart before being reused.

## What Theo actually demonstrates

### Why he moved development off his Mac

- 2:48 — His central problem is long-running agent work tied to an open laptop
- 5:21–6:14 — Tailscale connects his fleet; SSH automatically attaches to tmux so sessions survive disconnects
- 8:37–9:08 — His Mac holds an inventory and configuration guidance for the other machines
- 12:02–13:21 — He attributes heavy Mac CPU usage partly to security-policy checks and agent subprocesses; he also says the implementation is improving
- 14:24–15:55 — His small-file cleanup and cached-install demonstrations favor Linux, but the examples are workload-specific
- 18:46–24:31 — The network KVM supplies bootloader and recovery access; he describes it as an emergency interface
- 25:07–29:47 — A remotely running T3 Code instance restores screenshot sharing and lets work continue while his laptop closes

Source: [Linux video](https://www.youtube.com/watch?v=9tGrhrVKCrE), corresponding timestamp sections

### Why he wants a graphical agent interface

- 7:17–8:43 — Screenshots, readable history, project navigation, and switching between tasks reduce his organizational overhead
- 12:01 — A reboot has lost his tmux sessions; disconnect survival is not reboot persistence
- 13:22–14:06 — Image pasting over SSH is possible in his later setup, but he describes effort and bugs. The earlier blanket claim that images cannot be pasted over SSH is therefore too strong
- 14:43–16:52 — His complaint is interactive SSH fragility and phone usability, rather than inability to execute remote work
- 22:57–26:14 — He demonstrates separating the client interface from the host that runs the agents

His experience supports validating your chosen T3 interface while keeping SSH and CLI/herdr available for the work you prefer there.

Source: [Terminal video](https://www.youtube.com/watch?v=dLhcLqoff6k), corresponding timestamp sections

### What his filesystem experiment does and does not settle

- 3:48–6:03 — The comparison includes cached package installation and cleanup of many small files
- 18:47–25:37 — He compares worktree creation, concurrent creation, package import behavior, and storage consumption
- 22:34 — He still uses Btrfs for NAS/file storage while preferring a different setup for development
- 23:19 — He says most detailed benchmarking occurred after he had ruled out Btrfs and ZFS
- 27:08 — Ordinary Ubuntu/ext4 had already improved his experience enough that he originally planned to keep it
- 27:54 — His later XFS+VDO setup is on a development drive separate from the OS drive

Treat the results as his measurements on particular repositories and machines, not a universal filesystem ranking.

Source: [Filesystem video](https://www.youtube.com/watch?v=4wVNFaFDIn8), corresponding timestamp sections

## Corrections checked against primary documentation

ext4 supports hard links. A missing general reflink mechanism does not mean pnpm must duplicate every package file. Current pnpm docs explicitly identify hard-link support on ext4. [Kernel ext4 directory documentation](https://www.kernel.org/doc/html/latest/filesystems/ext4/directory.html), [pnpm import methods](https://pnpm.io/settings/node-modules#packageimportmethod)

XFS reflink and VDO solve different problems. XFS can share file extents with copy-on-write. VDO is a separate device-mapper layer for deduplication, compression, and thin provisioning beneath a filesystem. An XFS format alone does not produce the setup Theo tested. [XFS technical documentation](https://www.kernel.org/pub/linux/utils/fs/xfs/docs/xfs_filesystem_structure.pdf), [kernel VDO documentation](https://docs.kernel.org/admin-guide/device-mapper/vdo.html)

Today's pnpm auto behavior is platform-specific: Linux tries hardlink, then clone, then copy; macOS/Windows try clone, then hardlink, then copy. Check the installed pnpm version before assuming this applies to an older release. Package store and installation must share a filesystem for hard linking; being on the same physical drive is insufficient. [pnpm import methods](https://pnpm.io/settings/node-modules#packageimportmethod), [pnpm store placement](https://pnpm.io/settings/store#storedir)

## The small test worth doing first

This is a proposed validation sequence, not a claim that your server has already been checked:

1. Run one real repository and one agent on the 5700G host through the chosen T3 Code desktop app and T3 Connect
2. Close the Mac client and any SSH connection, then reopen it. Confirm the host process continued and that its task history and results are discoverable
3. Check that the host does not sleep, that the T3 background service stays running, that agent binaries are installed and authenticated there, and that the noninteractive SSH PATH can find them
4. Paste a screenshot into the remote T3 task and verify the agent can actually read it. Also check switching between tasks and the CLI/herdr workflow you want to keep
5. Measure worktree creation, offline cached installation, cleanup, and disk growth with fixed versions, one lockfile, and repeated runs. Compare equivalent warm-cache states
6. Check log growth and recovery access before adding parallel workers

A named CLI session solves connection loss; the chosen T3 workflow needs a running host service. Restart behavior and recovery after a reboot need a separate plan. Do not weaken Mac security protections to chase the video’s performance claims.

Benchmark interpretation: report the repository, filesystem, versions, package-import method, cache condition, and actual allocated space. Avoid clearing global caches on an active host; the kernel documents the performance cost. [pnpm install options](https://pnpm.io/cli/install), [Hyperfine benchmarking guidance](https://github.com/sharkdp/hyperfine#warmup-runs-and-preparation-commands), [kernel cache documentation](https://docs.kernel.org/admin-guide/sysctl/vm.html#drop-caches)

## Validate your chosen T3 Code connection

Use current documentation rather than copying the videos’ nightly commands. The project now documents direct LAN/tailnet pairing, desktop-managed SSH, and T3 Connect. A command-line host can use t3 serve with its private address, or t3 serve --tailscale-serve for tailnet HTTPS. The hosted web app needs an HTTPS endpoint and connects directly to the host; a pairing URL does not make an unreachable host reachable. T3 Connect offers a background service, and the host must remain running. Pairing grants future access to a device, so treat pairing URLs as credentials.

The desktop app and working T3 Connect are your selected workflow. Validate remote execution, screenshots, client reconnection, and host-service persistence as part of that setup. [Current T3 Code remote access documentation](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md)

## The related X claim

Theo’s [20 August post](https://x.com/theo/status/2090528543746965991) is directly verified: it promotes the claim that moving to Linux substantially improved his agent performance, particularly filesystem work. It is a personal performance claim accompanying the same topic, not an independent benchmark. The post text, author, and date were visible; its embedded media could not play in the research browser.

## Remaining evidence limits

- Full mirror-caption coverage was obtained, but official downloaded caption bytes and complete audio comparison were not
- The first video’s official YouTube transcript panel stayed loading. Its export returned a temporary path without a readable file
- The non-www transcribe address returned 502 after one reload; the verified www source succeeded
- The filesystem Arcmira page timed out in web retrieval, but its entire public caption body was readable in the cloud browser
- The Arcmira transcript-download click produced no completed download within 20 seconds. No account was created or premium transcript accessed
- I did not reproduce Theo’s benchmarks, verify every chart value, or establish his subscription economics and provider-policy claims as current facts

The recommendation is based on your existing fleet and verified source themes. It preserves your accepted architecture and leaves storage tuning for a measured bottleneck.

