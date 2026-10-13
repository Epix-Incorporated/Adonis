# Communication regression checks

Run from the repository root. The repository pins **Selene 0.31.0** and **Rojo 7.7.0** in `aftman.toml`. The standalone fixtures use **Lune 0.11.0** and its built-in `@lune/fs`, `@lune/luau`, `@lune/serde`, and `@lune/task` modules. Lune is a test runner, not a game dependency.

```powershell
# Use the pinned binaries on PATH, or equivalent absolute paths.
selene ./MainModule ./Loader
selene ./Tests
rojo build -o Adonis.rbxl
rojo build -o Adonis_AgentCheck.rbxm .github/build.project.json
Get-ChildItem -LiteralPath Tests -Filter *.spec.luau | ForEach-Object {
    lune run $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Fixture failed: $($_.Name)" }
}
git diff --check
```

If the Roblox standard library has not been generated locally, run the pinned `selene generate-roblox-std` first. Generated Roblox library/build artifacts are ignored. None of these commands publishes a place, changes datastores, or commits source.

| Fixture | Boundary exercised |
| --- | --- |
| `ChatTransportServer.spec.luau` | Real transport with deterministic engine substitutes: origin/permit authority, readiness/membership, read-only mute handling, pair reuse, close/join races, timeouts/capacity, help acceptance, actual private-chat controls. |
| `ChatTransportClient.spec.luau` | Real client transport: ready/send, no raw recipient relay, successful delivered text only, deduplication, histories, timeout/late receipt, announcement replacement without clearing stacking presentations, speech cancellation through Default/Unity/Aero manual and registry cleanup, command preflight. |
| `PrivateChatLifecycle.spec.luau` | Actual private-chat window and Default/Unity/Aero close implementations: removal cleanup, same-channel rejoin, delivered messages, replies, exactly-once manual/registry leave, and server removal during animated closure. |
| `CommandProvenance.spec.luau` | Actual command parser and alias formatting: literal arguments, generated templates, batches, overrides, actual actor, expiry, admission/completion/failure audit timing and persistence exclusions. |
| `NativeChatCommands.spec.luau` | Actual native registry and command dispatch: prefixes/synonyms, startup and late plugin registration, coalesced refreshes, invalid definitions, host collisions, personal aliases, refresh/cleanup, managed-channel guard, hidden/disabled interception, chat-only restrictions through aliases/batches, rate limiting, native broadcast submission, and canonical cross-server dispatch without destination alias expansion. |
| `AnnouncementCommands.spec.luau` | Actual announcement and warning handlers with real server transport: aliases, authored native submissions, custom title/body framing, presentation metadata, missing input, generated/sudo denial, and warning persistence independent of chat delivery. |
| `CrossServerCommunication.spec.luau` | Actual global commands and cross-server plugin: retired message routes, operational argument compatibility with older receivers, real-parser roundtrip validation, rejection of aliases/batches/loops, retained public-edit filtering/admission, and fixed restart status without supplied reason text. |
| `AliasUpdates.spec.luau` | Actual alias-save endpoint, client helpers and rename callback: bounded atomic updates, deletion-only legacy cleanup, throttling, synchronous registration, rollback, accepted client state, and one-request edits. |
| `AFK.spec.luau` | Actual AFK command, text policy, and jump cleanup: filtered labels for multiple targets, originating author under `sudo`, one shared admission, and no partial effects after cooldown or filtering rejection. |
| `TextPolicy.spec.luau` | Actual filtering and command wrapper: both filter stages, audience/author checks, shared admission, records, non-chat publication, retired announcement declarations, helper context, direct calls, filtered tag membership collisions, case-insensitive removal controls, and author-only debug diagnostics through `sudo`. |
| `Logging.spec.luau` | Entire projected rows, including descriptions and unknown fields; canonical metadata and non-chat detail provenance. |
| `Settings.spec.luau` | Mutation validation, text admission, operational/display separation, persistence-shaped records, different viewer handles, ranks/catalogs, legacy loaders without rank baselines, immutable fallback definitions, legacy redaction, and one ban-list projection per refresh. |
| `StartupMessages.spec.luau` | Immutable startup snapshots, unregistered notices, record projection, actual delayed notification sink, missing/special ranks. |
| `CommandErrors.spec.luau` | Fixed error projection and actual Process/Admin/ScriptEditor output sinks; unknown exceptions never become outgoing text. |
| `ModerationAudit.spec.luau` | Actual ban and time-ban producers retain resolved numeric targets, the originating actor, and safe reasons. |
| `PlayerData.spec.luau` | Actual player-preferences response keeps supported UI fields and excludes moderation records and unknown plugin fields. |
| `ProfileData.spec.luau` | Actual client telemetry producer, profile command, and UI value labels: strict technical fields, protected server-owned facts, invalid numeric/string inputs, and viewer permissions. |

Some fixtures extract a bounded function from its real source module to avoid booting the whole engine. Source anchors failing after a refactor require updating the harness and reviewing the exercised boundary; they are not proof of a product regression by themselves. Mock services deliberately force failure, timing, and privacy outcomes; their pass results do not validate Roblox's real account restrictions.

For an engine check, build an **unpublished** test place that loads the local `MainModule`. Before playing, verify `GameId == 0`, point the loader to that module, enable local/mock storage, disable real persistence, and isolate cloud/HTTP integrations and external plugins. Use `TextChatService` chat mode. Keep these test-only changes out of production configuration. Start the real Adonis UI, submit a command, and observe both native sending and recipient delivery events independently. A sender event or `Sending` status does not establish delivery.

The required account/privacy and operator checks are documented in [communication-compliance.md](../docs/communication-compliance.md#verification-and-release-gate). Do not restore a remote-body fallback if an engine test fails.
