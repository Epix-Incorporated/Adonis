# Communication and authored text

Adonis uses Roblox TextChannels for user-to-user messages, including admin announcements, and explicit non-chat filtering for moderation records and editable shared content. This document describes the first-party implementation, extension contracts, compatibility changes, and required release checks. It does not certify platform compliance or replace testing with real accounts.

## Policy basis

- [Chat guidelines](https://create.roblox.com/docs/chat/guidelines)
- [TextChannel API](https://create.roblox.com/docs/reference/engine/classes/TextChannel)
- [TextChatCommand API](https://create.roblox.com/docs/reference/engine/classes/TextChatCommand)
- [Non-chat and stored-text filtering](https://create.roblox.com/docs/ui/text-filtering)
- [Rate limiting public text inputs](https://create.roblox.com/docs/chat/examples/rate-limit-public-text-inputs)

Admin-written announcements use the same native delivery restrictions as other user messages. The shared 60-second admission applies to editable shared content, including persistent notices, names, and poll fields. Fixed system status and moderation actions remain available when user chat is unavailable; they never substitute a custom message body for a denied native delivery.

## Conversational delivery

The server owns channel creation, membership, presentation, command authorization, and lifecycle. It registers each managed channel before parenting it, calls `SetDirectChatRequester` before adding users, and uses native `AddUserAsync` eligibility. Its non-yielding delivery callback additionally checks current membership, readiness, base send permission, and Adonis mute state. Unmuting does not grant a receive-only participant permission to send.

An explicit command ingress creates an opaque origin associated with the actual player, invocation ID, original submission, and expiry. The parser tracks literal message arguments through aliases and batches. Generated alias text, argument overrides, loops, and `sudo` cannot initiate speech on another player's behalf. Chat commands receive their opaque input in `data.ChatInput`; plugins must not fabricate or reuse it.

Initial text returns only to its submitting client. That client calls `TextChannel:SendAsync` once for the authorized operation. Every recipient renders only their own successful `MessageReceived.Text`; empty, failed, duplicate, and source-less messages do not create conversation content. A successful sender result is telemetry, not proof of delivery to every recipient. There is no raw-message fallback or automatic retry.

Control remotes contain identifiers and server-selected metadata. They do not relay recipient bodies or freeform titles. Titles supplied by users are part of the channel text. Server control handlers validate the caller against current membership, authority, operation, and expiry.

| Surface | Behavior |
| --- | --- |
| `pm` and replies | One reusable channel per pair; multiple selected players receive separate conversations. |
| `privatechat` | Native group delivery with existing membership controls. New members receive subsequent messages; the server does not replay a transcript. Owner departure or closure ends the group. |
| `help` | Fixed request notifications remain available to admins. An optional reason uses a temporary requester channel with receive-only admins. The first authorized acceptance claims the request before teleporting. |
| `mpm`, `npm`, `notify`, `chatnotify`, `rbxnotify`, custom `alert` text and aliases | Native delivery followed by the existing Adonis presentation style. |
| `m`, `n`, `h`, `bc`, `cm`, `cn`, `sm`, `sn`, timed variants and aliases | Native delivery supplies announcements, hints, chat-window broadcasts, and both fields of custom titles/messages. System-style aliases attribute text to its actual sender. |
| `warn` | Records the authorized warning and a separately filtered moderation reason. The target receives fixed warning status; custom reason delivery uses native chat and can fail independently. |
| `talk` / `maketalk` | The selector chooses viewers; the bubble appears over the actual sender. |
| `tell` / `tts` | An attributed caption and local narration use the recipient's delivered text. Stop, session mute, replacement, closure, and cleanup cancel playback. |
| `bchat` | Existing self-only preview. |
| Terminal message | Native conversational transport with the terminal caller as author. |
| `gm`, `gtm`, global-message aliases, cross-server player messages | Unavailable until a native cross-server delivery contract exists; no messaging-bus body fallback. |

The setup timeout is 10 seconds, initial-send authorization expires 30 seconds after the original command submission, and transient/help channels last 30 seconds. PM channels expire after 15 minutes of inactivity. Pending sends are capped at 32 per player and managed channels at 1,024 per server. Local conversation history retains at most 200 delivered messages per channel; the local chat-history view retains at most 500 delivered messages across channels. Closing a channel removes its listeners and pending operations. Roblox's default chat UI may also display native channel messages; Adonis does not replace host chat configuration to hide them.

Custom titles and bodies are sent together as plain channel text. Title line breaks are normalized to spaces after checking the original submission; recipients split their delivered text at its first newline. If filtering removes that framing, the full delivered text appears under a fixed author title. Control metadata carries only the title mode, never the title's text. Timed announcement display accepts finite positive durations capped at 3,600 seconds; automatic duration uses the delivered body length. Presentation duration does not extend channel membership or authorize additional sends.

### Native command compatibility

Modern chat uses registered `TextChatCommand` aliases as the command ingress. `Player.Chatted` and client `SendingMessage` are not replayed as modern commands because those paths cannot establish that private command text was intercepted before public delivery. Managed conversation channels never execute Adonis commands.

Registered command-like text is rejected before a conversational send, including mixed-case aliases and aliases followed by arguments. Near-matches remain ordinary conversation text. Host-owned alias collisions are preserved, so an alias owned by another system remains that system's responsibility.

`ChatCreateRobloxCommands` now controls native autocomplete visibility. Native command interception remains registered when autocomplete is hidden or the viewer lacks command permission. With `ChatCommands=false`, conversational aliases and configured aliases remain intercepted and return a fixed disabled message without execution. Use the command bar in this mode.

Global aliases and eligible personal aliases beginning with configured command prefixes participate in native interception. A personal alias is still expanded using the actual caller's configuration. Unprefixed personal aliases are supported through the command bar and keybinds. Native batches must begin with a registered alias followed by its argument boundary: use `:fly | :pm player message`, or use the command bar for `:fly|:pm player message`.

Personal alias updates are atomic and limited to one attempt per second, 64 entries, 128-byte names, and 4,096-byte command expansions. A native personal alias token must be at most 64 bytes and use a configured prefix followed by ASCII letters, digits, underscores, or hyphens. Other accepted aliases are command-bar/keybind inputs. Successful saves install native interception before acknowledging the update; rejected saves preserve the previous configuration and client state. Unchanged native handlers are reused. These internal resource limits are separate from the shared editable-text cooldown.

An existing saved map with more than 64 aliases is preserved but is wholly command-bar/keybind-only until reduced to a map within the limits. The Aliases editor permits deletion-only cleanup of legacy maps that exceed count or length limits; retained entries must remain unchanged. Additions and other edits must meet the current limits. The editor displays the native-chat requirements; unsupported aliases must not be entered through public chat. No partial subset of an oversized legacy map is registered.

## Non-chat filtering and publication

Commands declare `UserText = {Kind, Args, Audience}`. `Args` contains displayed argument positions. Non-chat `Audience = "Broadcast"` specifies the filter projection, not the delivery recipient list: even targeted moderation reasons use a broadcast-safe snapshot for later approved audit views. Chat audience names describe the command's recipient selection.

| Kind | Contract |
| --- | --- |
| `Chat` | Native TextChannel delivery; no non-chat filtering fallback. |
| `Announcement` | Retired command declaration; rejected before publication. Use `Chat` for user messages. Existing record compatibility is not permission to relay a message. |
| `PublicEdit` | One shared admission per actual author per 60 seconds, then broadcast filtering. |
| `Moderation` | Broadcast filtering; on failure, perform the authorized action with a fixed unavailable-reason message. |

The command-function wrapper enforces declarations for normal dispatch, direct calls, and registered built-in plugins. Dynamic text producers also enforce admission and filtering at their publication boundary. Numeric-looking display strings are still text. Numeric operations, author-only preferences, fixed system messages, and viewing an accepted value do not consume this admission. No rank bypass exists. Admission is reserved before yielding, shared across target selections and aliases, and retained across same-server reconnects. A failed filtering attempt consumes its reserved admission. Cooldown state is server-scoped.

Removal controls are case-insensitive: `hide` for character names and `off`/`false` for persistent notices remove the existing content without another admission. Other text, including control words with extra characters or whitespace, still requires filtering and admission.

### Helper contracts for plugins

| Helper | Result and responsibility |
| --- | --- |
| `service.TryFilter(text, author, recipient, broadcast)` | Returns safe text or `nil, failureCode`. Both filtering stages must succeed. Use a real connected author and the correct audience. |
| Legacy `Filter`, `BroadcastFilter`, `LaxFilter` | Preserve their legacy call shapes but return fixed safe text on failure. They no longer return the original source or skip numeric-looking strings. Prefer explicit failure handling. |
| `TextPolicy.FilterBroadcast` / `FilterForUser` | Explicit non-chat success/failure wrappers. Never use these to relay conversations. |
| `TextPolicy.TryPublicEdit(author)` | Atomically reserves admission; returns `allowed, remainingSeconds`. Reserve once for an operation before filtering or changing shared state. |
| `TextPolicy.PrepareArguments(author, args, metadata)` | Clones arguments, reserves one admission if applicable, filters declared fields, and returns filtered arguments plus records. |
| `TextPolicy.CreateRecord(text, author, kind)` | Creates an immutable safe-only record with version, author ID, kind, and filtered text. This helper filters; callers still need the relevant public-edit admission. |
| `TextPolicy.GetRecordText(record)` | Uses a privately trusted current-session snapshot; otherwise re-filters a valid persisted record with its real online author. Returns unavailable on missing provenance or offline authors. |
| `TextPolicy.GetPublicationText(value, authorOrRecord)` | Publication helper for non-chat UI. Explicit records retain their provenance; command calls inherit actual-author context. |
| `TextPolicy.FormatPublishedRecord(record, presentation)` | During an authorized published command, derives fixed numeric author attribution or an attributed hint from that invocation's trusted record. Other records and arbitrary formats are rejected. |
| `TextPolicy.GetCommandAuthor(actor)` | Resolves the actual author for a new non-chat submission inside a command, including `sudo`. Do not use the viewing admin to reattribute a stored record. |
| `ChatTransport.SubmitCommand(author, recipients, text, input, kind, presentation, options)` | Consumes the opaque `data.ChatInput` from explicit command processing, resolves native eligibility, and authorizes the submitting client to send. A direct/generated call without that input is rejected. |
| `Functions.Message`, `Hint`, `Notify`, `Notification` | Non-chat UI helpers for system status, approved moderation displays, and shared editable content. They filter titles/bodies and preserve existing call signatures; they are not user-message transports. |
| `Logs.AddAudit(category, eventId, actor, metadata)` | Records approved canonical identifiers, numeric actor/target data, fixed outcomes, and optional separately filtered non-chat detail records. |
| `Logs.Project` / `ProjectConsole` | Produce safe outbound rows, including descriptions. Raw chat/PM/remote/plugin/error text is unavailable. |
| `Core.ProjectSetting`, `GetSettingText`, `GetVariableText` | Read display-safe configuration or runtime overrides without publishing operational raw strings. |
| `Core.GetSettingsTableEntries` / `ResolveSettingsEntry` | Issue and resolve caller-bound, expiring entry handles; removal does not require returning raw labels. |
| `server.AddSystemMessage` | Registers an immutable snapshot of developer-authored startup text. Direct unregistered insertions into `server.Messages` are redacted unless they contain a valid non-chat record. |

Privileged plugins remain trusted server code. Outside a command context, authorless helper calls and `AddSystemMessage` are reserved for developer-authored literals. Passing player text through these literal-only contracts, calling `Remote.MakeGui` with unfiltered text, or publishing through arbitrary custom scripts bypasses the supported extension contract. Third-party scripts are not automatically made compliant by this patch. Do not accept client-provided author identities, presentation metadata, publication records, or "already filtered" flags.

A command registered through the normal command registry can use the following conversational boundary. The server still chooses and authorizes recipients; the command does not call a recipient GUI with its argument text.

```luau
UserText = {Kind = "Chat", Args = {2}, Audience = "SelectedPlayers"};
-- Starts separate native conversations for this explicitly submitted command.
Function = function(player, args, data)
    local recipients = service.GetPlayers(player, args[1])
    server.ChatTransport.SubmitCommand(player, recipients, args[2], data.ChatInput, "PrivateMessage")
end;
```

`sudo` retains the execution target for command semantics while preserving the real originating author for non-chat publication, filtering, cooldowns, and audit attribution. A system invocation without trustworthy author provenance cannot publish arbitrary shared text; moderation uses a fixed reason. It cannot manufacture conversational speech.

### Cross-server and persisted text

The originating server filters poll fields and moderation reasons using the real author. Authenticated cross-server handlers accept versioned server-created publication envelopes for public edits and moderation, validate record shapes, and deduplicate publication IDs for five minutes. They reject announcement publications and legacy raw-text message delivery. Published-command authorization is private, single-use, and bound to the exact command, actor, and arguments. Forwarding does not create a fresh edit allowance. Restart progress announcements contain fixed status and numeric timing; the supplied reason remains part of the moderation action.

Operational cross-server commands include a complete canonical command string for older receivers and separate arguments for updated receivers. Both forms must parse to the same command and arguments; structured input that cannot be represented losslessly is rejected before transport. Unknown commands, aliases, batches, and command loops are rejected. Updated receivers dispatch the canonical command with structured arguments without expanding local aliases; older receivers retain their existing command parser. The legacy `Message` and `ServerChat` bus routes are disabled in both directions.

Dynamic `cross change`, `cross tag`, and `cross disguise` are rejected because their destination-dependent text cannot be prepared reliably at the origin. This includes numeric `cross change`; use an appropriate local operation until an explicit cross-server contract exists. Arbitrary cross-server conversational chat relays are disabled.

Newly persisted user text carries `Version`, `AuthorUserId`, and `Kind`. Existing datastore keys and retention remain in place; no bulk rewrite or deletion occurs. Saved settings retain operational values separately from display records in `SavedSettings.__AdonisTextRecords`. Saved table edits retain their provenance alongside the existing edit data.

A verified current-session snapshot remains displayable after its author leaves. A record loaded from persistence is re-filtered only when its reliable real author is online. Legacy, unattributed, or offline-author text becomes fixed unavailable text while operational identifiers and safe metadata remain usable. Settings editors validate keys, types, technical selector syntax, and entry handles. Redacted placeholders are never used as configuration replacements.

## First-party text-sink coverage checklist

These entries describe source coverage. The release matrix below distinguishes automated contracts from real-account validation.

| Covered surface | Enforcement and display boundary |
| --- | --- |
| PM, group conversations, help reasons, directed notifications, custom alerts | Server/client `ChatTransport`; default and embedded TransBlack/Steampunk PM implementations; no legacy reply tickets or server transcript replay. |
| Talk bubbles and speech | Actual-author native message source; recipient delivery drives caption/bubble/audio. |
| Announcements, hints, broadcasts, custom titles | `Chat` metadata; actual-author native delivery supplies every displayed user field. Global-message relays are disabled. |
| Persistent notices, ban/lock labels, notes | `PublicEdit` metadata; records and projected retrieval. |
| Names/display names, tags, string stats, team/tool names | Shared admission and filtering at static or dynamic command boundaries; numeric stat changes stay numeric. |
| Camera, waypoint, reserved server, starter-script labels | Shared admission, safe labels, authored reserved-server records. |
| Poll questions, answers, descriptions, cross-server results | Origin-filtered public-edit records and versioned publication envelopes. |
| Kick/warn/ban/time-ban/shutdown reasons | Actual-author moderation records; failure preserves the action with fixed text; retrieval uses safe projection. Warning messages additionally require native chat delivery; restart broadcasts carry fixed progress only. |
| Command, remote, PM, chat, task, error and console logs | Approved metadata producers and outbound projections; raw bodies, hidden descriptions, unknown plugin text, and raw remote arguments are suppressed. |
| `chatlogs` | Local history of messages delivered to the viewing client; no server-wide transcript. |
| Settings `SetSetting`, `SaveSetSetting`, `SaveTableAdd`, shared lists/whitelist | Input validation, shared admission for string edits, provenance, safe labels, caller-bound removal handles, persistence and synchronization checks. |
| Admin/rank lists, command lists, insert/music catalogs | Trusted developer baselines or safe projections; unknown external labels are unavailable. |
| Welcome/startup notices and test/debug/error echoes | Safe rank fallback, immutable approved startup snapshots, fixed exceptions, safe console projection; raw filtering diagnostics remain visible only to their actual author, including under `sudo`. |
| Player-data response | An explicit UI allowlist includes supported caller preferences and permission metadata; moderation records and unknown plugin fields are excluded. |
| Player profile device information | Only validated technical fields from the inspected client are displayed; client replies cannot overwrite server-owned rank, mute, or source-place information. |
| Author-only aliases/keybinds/preferences/playlists; fixed system messages | Remain author-only or developer-authored; are not repurposed into shared text without the appropriate publication boundary. |

## Verification and release gate

Run the focused source-executing fixtures and repository checks in [Tests/README.md](../Tests/README.md). They substitute engine services, including filter output and privacy eligibility; they cannot establish Roblox's actual recipient filtering, account restrictions, native UI, or moderation permissions.

Local Studio probes used unpublished places, the local `MainModule`, mock storage, disabled persistence, and isolated integrations. An explicit Adonis command-bar PM submission reached one native client send. Separate engine probes confirmed both `:pm` and `/:pm` native command interception. A production-mode announcement smoke test submitted `m/n/h/bc/cm` through the client command ingress and observed one native send attempt per submission, zero received messages, and no premature body display. The single-client probes did not establish successful recipient delivery. No place publication or real-account privacy test is included in this change.

Before release, record account eligibility, relevant experience settings, results, and engine version for every unchecked row:

| Acceptance area | Automated/source evidence | Required engine/account evidence |
| --- | --- | --- |
| PM/replies/multiple recipients | Pair reuse, author binding, deduplication, recipient-only rendering, capacity/lifecycle contracts | Two eligible accounts exchange/reply; multi-target sends remain separate; restricted recipients see no content. |
| Groups/help | Actual group controls, owner closure, revoked members, competing help acceptance, expiry; Default/Unity/Aero manual closure, registry destruction, and cleanup during an animated close | Join/remove/leave during live delivery; first help acceptance teleports exactly once; unavailable reason delivery leaves fixed notice usable. |
| Announcements/warnings | Actual command handlers, styles, native-send authority, custom-title framing, fixed warning status and moderation persistence, retired global relays | Eligible and restricted accounts receive only permitted text through every announcement style; custom title filtering and warning delivery fail safely. |
| Command inputs | Actual alias/batch parser, generated/sudo rejection, native alias registration, disabled sinks | Command bar, native chat, aliases, batches, and keybinds produce one send per explicit body and no public private-body echo. |
| Command interception | Exact/mixed-case aliases, arguments, near-matches, managed channel guard, host collisions | Repeat using native UI and host commands; verify denied/hidden commands still consume private input. |
| Failure/lifecycle | Readiness timeout, hung send, late receipt, replayed controls, forged membership, pending/channel bounds | Disconnect/reconnect, real send failures, delayed source replication, idle expiry, and no raw fallback. |
| Filtering/cooldown | Both filter stages fail, invalid UTF-8, numeric-looking text, concurrent admission, 60-second boundary, alias/direct-call/context checks | Actual platform filtering and displayed multi-line text for distinct recipients; shared edits remain unavailable before 60 seconds. |
| Presentation/privacy | Delivery-driven bubbles/captions/audio, base send permission under mute, theme paths | Real restricted accounts, mute/unmute, recipient-specific results, Default/TransBlack/Steampunk, native UI coexistence, speech stop/mute. |
| Logs/settings | Complete safe projections, hidden fields, legacy/offline records, different viewer handles, reload-shaped records, duplicate envelopes | Inspect real outbound payloads as two admins; isolated persistence reload and two-server synchronization. |
| Build/runtime | Pinned lint/builds, focused fixtures, isolated local startup/send | Real-account privacy delivery remains a release gate even after all automated checks pass. |

## Native moderation view for operators

Expanded moderator visibility uses Roblox's native read-only moderation feature. Adonis does not import or reconstruct that feed. No supported API for importing the privileged feed into Adonis logs was found in the referenced documentation.

For a group-owned experience:

1. In Creator Hub, switch to the owning group, open the account switcher again, and select **Roles**.
2. Grant the appropriate moderator role the experience moderation permission. Current group documentation calls this **Moderate experiences**; the rollout announcement describes its read-only chat permission.
3. The moderator must be at least 18 and age-checked. While in the experience, enable **read-only chat for moderation** in Roblox's settings.
4. Use the native read-only view for expanded chat visibility. Sending remains subject to Roblox's communication restrictions. An Adonis admin rank does not grant this Roblox permission.

This group permission also grants moderation/ban capabilities, so assign the role accordingly. See the [official rollout announcement](https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685) and [current group permissions](https://create.roblox.com/docs/projects/groups).
