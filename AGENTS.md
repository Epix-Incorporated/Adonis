# Agent guide

Adonis is a Roblox server moderation and administration system written in Luau. This guide applies to this repository. Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution policy and [SECURITY.md](SECURITY.md) when handling a security report.

## Working boundaries

- Start with `git status --short` and inspect the relevant source before editing. Preserve unrelated changes and work in the current checkout; sibling repositories are separate projects.
- Keep changes focused on the request. Local inspection, scoped edits, and appropriate local checks can proceed without repeated confirmation. Do not commit, push, deploy, publish, send messages, or mutate external systems unless explicitly requested.
- Contributions target `master`, not `release`, per `CONTRIBUTING.md`. Do not switch branches, reset work, or rebase automatically to satisfy that policy.
- Check repository claims against source, configuration, diffs, and appropriate runtime evidence. Use current primary documentation for changing Roblox APIs, external tooling questions, or material uncertainty.
- Keep this file as the shared agent guidance. Tool-specific instruction files should point here rather than duplicate it.

## Where to look

| Area | Source and purpose |
| --- | --- |
| Loader and configuration | `Loader/Loader/Loader.server.luau` selects the module and reads `Loader/Config/Settings/`, plugins, themes, and editor metadata. |
| Server startup | `MainModule/init.luau` requires `MainModule/Server/Server.luau`, which builds the environment and initializes cores and plugins. |
| Server behavior | `MainModule/Server/Core/`: `Commands.luau` loads command definitions, `Process.luau` processes commands/remotes, `Admin.luau` handles permissions, and `Core.luau` handles loading and persistence. |
| Commands and built-in plugins | `MainModule/Server/Commands/` contains command tables grouped by role/category; `MainModule/Server/Plugins/` extends server behavior. |
| Client | `MainModule/Client/Client.luau`, `Core/`, and `Plugins/` implement client startup, remotes, UI, and client behavior. |
| UI | `MainModule/Client/UI/` contains theme code and Roblox models. `MainModule/Client/Core/UI.luau` manages UI creation, registration, and cleanup. |
| Shared facilities | `MainModule/Shared/Service.luau` implements the service abstraction; other shared modules provide utilities used across the runtime. |
| Settings defaults | `MainModule/Server/Dependencies/DefaultSettings.luau` provides fallback settings, descriptions, and editor order. |
| Release history | `MainModule/Shared/Changelog.luau` contains the in-game changelog; `Loader/Version.model.json` records the loader version. See the changelog guidance below before editing either. |
| Build and lint | `aftman.toml`, `selene.toml`, `default.project.json`, `.github/build.project.json`, and `.github/workflows/{lint,build}.yml`. |

## Editing conventions

- Follow nearby Luau patterns and `.editorconfig`: tabs with width 4 for Lua/Luau, JSON, and TOML; LF line endings. Prefer `task.wait()` and interpolated strings for new code, preserving intended behavior.
- Add or update documentation comments for properties, functions/methods, and classes you introduce or modify, explaining their purpose and contract. Comments should help future developers; omit task history, dates, and remarks directed at the requesting user.
- Preserve the module's existing entrypoint and environment conventions. Core, command, and plugin modules do not all have the same signature: inspect their loader before changing `Vargs`, `GetEnv`, `setfenv`, `server`, `client`, or `service` usage. Preserve initialization hooks and ordered core loading.
- For commands, follow neighboring definitions: `Prefix`, `Commands`, `Args`, `Description`, `Category`, `AdminLevel`, and `Function`. Preserve relevant flags and use existing player-selection and permission helpers. Check the path through `Server/Core/Commands.luau`, `Process.luau`, and `Admin.luau`; a command's folder or filename alone does not enforce permission.
- For loader plugins, use `Loader/Config/Plugins/Server-Example Plugin.luau` or `Client-Example Plugin.luau`. Their names must start with `Server:`/`Server-` or `Client:`/`Client-`, respectively. Built-in plugins have a different loading path; do not apply loader naming rules to them.
- When adding or changing a setting, check the appropriate `Loader/Config/Settings/` module, `MainModule/Server/Dependencies/DefaultSettings.luau`, and both `Descriptions.luau` and `Order.luau` under `Loader/Config/InGameSettingsEditorSettings/`. Keep applicable defaults and editor metadata consistent.
- Trace both ends of remote changes through server/client `Core/Remote.luau` and `Core/Process.luau`. Preserve server-side input validation and authorization; client UI restrictions alone do not authorize an action.
- For UI changes, inspect the selected theme and its fallback as well as `Client/Core/UI.luau`. Preserve registration and cleanup conventions; inspect `.rbxmx`, `.model.json`, and `.meta.json` companions before renaming or moving modules.
- `MainModule/Client/UI/Modern/Components/Packages/` contains vendored dependencies and is excluded by `selene.toml`. Avoid incidental edits there, retain upstream notices in dependencies, and do not add unrelated reformatting or generated models to a patch.

## Maintaining the changelog

- Follow [CONTRIBUTING.md, Changelog Policy](CONTRIBUTING.md#5-changelog-policy). For notable behavior changes, include proposed release-note wording in the handoff or PR description; maintainers assemble release entries from contribution titles. Do not insert unreleased work into an existing released section or bump versions during an ordinary feature/fix task.
- The authoritative changelog is `MainModule/Shared/Changelog.luau`, a returned Luau table of strings displayed in-game. `MainModule/Server/Server.luau` also derives `server.Version` from its first string. Preserve the leading `Version: ...` entry, display hints, quoted-string syntax, separators, and historical entries.
- When release preparation is requested, add the new section above previous releases, below the display preamble, with a blank-string separator. Follow the existing header format: `[v<version> YYYY-MM-DD HH:MM UTC] @<maintainer>` or `[Patch v<version> YYYY-MM-DD HH:MM UTC] @<maintainer>`. Use the agreed release version, actual release timestamp, and responsible maintainer; do not invent them or introduce a different versioning scheme.
- Release notes are usually broken up in to two parts: a Git log derived PR list and a custom
- `genchangelog.sh` and its Windows wrapper `genchangelog.bat` are release helpers, not routine checks. They are either used by maintainers before uploading a new release or alternatively (not currently but in the future) by automated Github Actions, cron jobs or other processes.
	- For usage documentation of the script you must read the brief documentation block at the beginning of the bash script.
	- The script will automatically updated the `Loader/Version.model.json` value as well as the changelog formatted version.
	- The script will only generate entries for all merged PRs since the last release. Commits that are not part of PRs must be manually entered to the changelog.
	- A caveat of note is that entries for merged PRs may already be entered to the changelog manually by maintainers. The script is unable to support this currently so care must be taken to not create dublicate entries.
- Write concise, present-tense entries describing the user-visible behavior: for example, `Fix :nuke lasting indefinitely with large sizes`. Use actual command usage names such as `:nuke`, not internal identifiers. Include contributor attribution and PR numbers only when verified; avoid task-specific commentary and unsupported claims of testing.
- For an authorized release version change, keep the first changelog string, new release header, and numeric `.Value` in `Loader/Version.model.json` consistent. Release preparation does not authorize tagging, publishing, or deployment.
- After a changelog edit, inspect the exact diff for misplaced entries, damaged history, invented metadata, and version mismatches. Run `selene MainModule/Shared/Changelog.luau`; if the loader version changed, parse `Loader/Version.model.json` as JSON as well. Apply the relevant build/Studio checks below if runtime formatting or consumption changes; report unavailable checks explicitly.

## Tool setup and local checks

Run commands from the repository root. `aftman.toml` is the version authority (currently Rojo 7.7.0 and Selene 0.31.0). With [Aftman installed](https://github.com/LPGhatguy/aftman#installation), install the configured tools and verify the resolved versions:

```sh
aftman install
rojo --version
selene --version
```

Do not upgrade pins or replace the toolchain as part of an unrelated change. If tools are unavailable, state which checks could not run.

Choose checks proportional to the change:

```sh
# Generate Selene's Roblox definitions if missing or stale; CI refreshes its cache weekly.
selene generate-roblox-std

# Example of a focused lint check; replace the path with the changed Luau files.
selene MainModule/Server/Commands/Players.luau

# The full source lint command used by CI.
selene ./MainModule ./Loader

# Build the local test place described by default.project.json.
rojo build -o Adonis.rbxl

# Build the model snapshot using the same project as CI.
rojo build -o Adonis_AgentCheck.rbxm .github/build.project.json
```

For code changes, lint the affected files; use full lint and the relevant build for broader changes. For documentation-only edits, check accuracy, paths/links, and `git diff --check`; runtime checks are unnecessary unless the documentation changes a runtime procedure. Inspect each command's exit status. `build.bat` and `build.sh` run multiple steps without explicitly stopping after a failure, so their final status alone is insufficient evidence that lint passed. In PowerShell, inspect `$LASTEXITCODE` immediately after each native command.

Build outputs named above and generated `roblox.yml` are ignored by `.gitignore`. Inspect the working tree after checks and keep generated artifacts out of the patch. The configured CI checks lint and build; it does not define an Adonis unit-test runner. The `.spec.luau` files inside vendored packages are dependency tests, not evidence that Adonis runtime behavior is covered.

## Roblox Studio verification

1. Use an unpublished local test place for routine validation. Open the local build or run `rojo serve` with the Studio Rojo plugin against the intended test place. `default.project.json` maps the source to `ServerScriptService/Adonis_Rojo`, with `MainModule` and `Adonis_Loader` as siblings. Avoid duplicate loaders.
2. Verify the loader is using that local `MainModule` before claiming a checkout was tested. The loader has `DebugMode = true` and `NightlyMode = true`; debug mode searches for a sibling ModuleScript named `MainModule`. If it is missing, the loader can still fetch a remote module, so successful startup alone does not prove local source was exercised.
3. Keep persistence and integrations isolated. `DataStoreEnabled = false` does not stop player-data saving. `LocalDatastore = true` selects mock storage, but `MainModule/Server/Dependencies/DataStoreService/init.lua` probes a real datastore when required in a published Studio place, before that flag is checked. An unpublished local place (`game.GameId == 0`) avoids that probe. Keep temporary test settings out of the final patch, and do not enable live integrations or write production data without authorization.
4. Exercise the changed behavior with the appropriate server/client play session. For commands and remotes, cover permitted and denied callers, missing/invalid arguments, and relevant player/character lifecycle cases. For UI, inspect the affected theme, interactions, and cleanup. Capture focused server/client output and screenshots or video when they help demonstrate behavior.
5. When using Studio automation, enumerate current instances, select the intended place by name, and inspect its play state before acting. Do not reuse cached instance IDs. Establish authorization for the target before modifying a game; a connected Studio window alone does not identify the intended test place.

A successful Rojo build verifies packaging, and Selene verifies lint rules. Neither proves Roblox runtime behavior. Report any unavailable Studio verification explicitly.

## Finishing work

- Inspect the final diff and `git status --short`, including new files; run `git diff --check`.
- Have an independent review/self-evaluation agent inspect the final output against the request and exact source. Fix supported findings within scope and recheck affected work. If independent review is unavailable, state that limitation.
- Report what changed, checks actually run and their results, and material unverified behavior. Do not describe source inspection, a lint pass, or a build as a successful playtest.
- Follow the existing PR template when a PR is explicitly requested; provide Studio proof for substantive behavior changes as required by `CONTRIBUTING.md`. Apply the changelog guidance above and leave release versions and publication workflows alone unless the task requires them.
