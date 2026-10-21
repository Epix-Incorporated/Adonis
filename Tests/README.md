# Lune smoke test

Run from the repository root with Lune 0.11.0:

```sh
lune run Tests/LinkedList.spec.luau
lune run Tests/AdminAPI.spec.luau
selene ./Tests
```

`LinkedList.spec.luau` loads the actual shared linked-list module and checks insertion order, node removal, count updates, and bounded insertion. `AdminAPI.spec.luau` runs the actual `Core.StartAPI` implementation with minimal service/admin substitutes and checks public admin calls, argument filtering, keyed read-only access, and the disabled API setting. Neither test boots Roblox or verifies engine behavior.

The CI workflow installs Lune 0.11.0 and runs every `Tests/*.spec.luau` file. Keep standalone tests focused on behavior that can be exercised reliably with the current source and Lune's runtime.
