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
selene ./Tests
```

* `LinkedList.spec.luau` loads the actual shared linked-list module and checks insertion order, node removal, count updates, and bounded insertion. 
* `AdminAPI.spec.luau` runs the actual `Core.StartAPI` implementation with minimal service/admin substitutes and checks public admin calls, argument filtering, keyed read-only access, and the `disabled` API setting. 
* `AdminCore.spec.luau` tests the actual permission and rank/cache methods from `Admin.luau`.
* `AdminBans.spec.luau` tests the actual ban lookup, expiry, persistence, and removal methods.
* `AdminAuthority.spec.luau` checks target-level and self-target authority decisions.
* `AdminAliases.spec.luau` tests alias matching, formatting, blacklist, and alias infinite recursion.
* `AdminCommandWrappers.spec.luau` verifies that the command wrappers preserve arguments and execution context and restrict non-admin execution to player-level commands.
* The Admin tests use lune, which is only a substitute - none boot Roblox or verify engine behaviour.

The CI workflow installs Lune 0.11.0 and runs every `Tests/*.spec.luau` file. Stand-alone tests should be kept focused on behaviour that can be exercised reliably, with the current source (no test-driven development on master!) and Lune's runtime.
