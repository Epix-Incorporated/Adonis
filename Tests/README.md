# Lune smoke test
Basic unit tests for some Adonis functions, intended to catch bugs and errors before Roblox testing.

Run from the repository root with Lune 0.11.0:

```sh
lune run Tests/LinkedList.spec.luau
lune run Tests/AdminAPI.spec.luau
lune run Tests/AdminCore.spec.luau
lune run Tests/AdminBans.spec.luau
lune run Tests/AdminAuthority.spec.luau
lune run Tests/AdminAliases.spec.luau
lune run Tests/AdminCommandWrappers.spec.luau
lune run Tests/AdminCommandRegistry.spec.luau
lune run Tests/AdminAssignments.spec.luau
lune run Tests/AdminMute.spec.luau
lune run Tests/AdminCooldownUpdates.spec.luau
lune run Tests/AdminFormatting.spec.luau
lune run Tests/AdminIdentity.spec.luau
selene ./Tests
```

* `LinkedList.spec.luau` loads the actual shared linked-list module and checks insertion order, node removal, count updates, and bounded insertion. 
* `AdminAPI.spec.luau` runs the actual `Core.StartAPI` implementation with minimal service/admin substitutes and checks public admin calls, argument filtering, keyed read-only access, and the `disabled` API setting. 
* `AdminCore.spec.luau` tests the actual permission and rank/cache methods from `Admin.luau`.
* `AdminBans.spec.luau` tests the actual ban lookup, expiry, persistence, and removal methods.
* `AdminAuthority.spec.luau` checks target-level and self-target authority decisions.
* `AdminAliases.spec.luau` tests alias matching, formatting, blacklist, and alias infinite recursion.
* `AdminCommandWrappers.spec.luau` verifies that the command wrappers preserve arguments and execution context and restrict non-admin execution to player-level commands.
* `AdminCommandRegistry.spec.luau` checks command prefix/alias caching, lookup, search, and permission updates.
* `AdminAssignments.spec.luau` checks rank assignment, reassignment, temporary access, removal, and persistence requests.
* `AdminMute.spec.luau` checks configured, Trello, and web-panel mutes with identity matching.
* `AdminCooldownUpdates.spec.luau` checks player, server, and cross-server cooldown timestamps and system-command exclusions.
* `AdminFormatting.spec.luau` checks split limits, quoted arguments, explicit arguments, and command usage formatting.
* `AdminIdentity.spec.luau` checks user/name matching and group, asset, gamepass, and subscription requirements.
* The Admin tests use lune, which is only a substitute - none boot Roblox or verify engine behaviour.

The CI workflow installs Lune 0.11.0 and runs every `Tests/*.spec.luau` file. Stand-alone tests should be kept focused on behaviour that can be exercised reliably, with the current source (no test-driven development on master!) and Lune's runtime.
