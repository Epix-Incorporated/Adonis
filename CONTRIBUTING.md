<div align="center">

# 📜 Adonis Contribution Policy

![Logo of Epix Incorporated](https://user-images.githubusercontent.com/81153405/175760639-fc3b2352-8066-48cc-b2e6-2ea0ad69e33e.png)

Adonis is an ever-expanding, frequently updated, and sometimes complex system.
To keep Adonis functional and somewhat readable rather than a tangled mess, this document sets out the policies governing contributions to consider before submitting a pull request:

## 1. Governance

- Pull requests (PRs) are reviewed and approved by [@Sceleratis](https://github.com/Sceleratis) or any of the appointed community maintainers:  
  [@Coasterteam](https://github.com/Coasterteam), [@joritochip](https://github.com/joritochip), [@Expertcoderz](https://github.com/Expertcoderz), and [@Dimenpsyonal](https://github.com/Dimenpsyonal).
- Maintainers may edit PR titles, descriptions, and labels for ease of classification.
- Community members are allowed and encouraged to comment on, review, and provide feedback on PRs, but final approval rests with maintainers.

## 2. Scope of Contributions

- **Permitted Contributions:**  
  - Additions or modifications to Adonis features, commands, or systems.
  - Bug fixes and stability improvements.
  - Documentation and wiki improvements.
  - Tutorials or technical references to support users and plugin developers.

- **Prohibited Contributions:**  
  - Code or features that violate Roblox’s rules or could endanger games using Adonis.
  - Any form of obfuscated code, either intentional or unintentional.
  - **Note**: There is a very clear/obvious difference between unavoidably complex code and intentionally complicated code. Maintainers will check all file changes before merging and can usually spot something abnormal quickly.
  - Contributions that add unnecessary complexity without clear benefit.

## 3. Pull Request Standards

- **Titles:**  
  - Must be concise, written in the present tense, and clearly describe what is being added, changed, or fixed.
  - Example formats:  
    - `Add :somenewcommand`  
    - `Fix :somecommand not accounting for XXX`  
    - `Add confirmation prompt for :somecommand to prevent misuse`  
  - Adonis commands must be referenced by their usage form (e.g. `:somecommand`), not the internal identifier (e.g. SomeCommand).

- **Descriptions:**  
  - Must provide a comprehensive list of changes.
  - Should explain the rationale behind the change.

- **Proof of Functionality:**  
  - PRs should include evidence (e.g., video, screenshots) demonstrating that the contribution works in Roblox Studio.
  - Exceptions: small, obvious fixes such as typos or trivial adjustments.

- **Labels:**  
  - PRs should include relevant labels where possible.
  - Maintainers may add or adjust labels after submission.

## 4. Code Quality and Style

- There is no set styleguide for Adonis code, however contributions should match the style of surrounding code.
- The [Roblox Luau Style Guide](https://roblox.github.io/lua-style-guide/) should be followed where applicable.
- English must be the language used for variable names and user-facing text.
- Contributors must ensure code is tested prior to submission.

## 5. Changelog Policy

- The changelog is the record of all notable changes.
- Each release of Adonis is documented within the changelog – Adonis uses two forms of releases:
- Full releases: most PRs are released in full releases.
- Patch releases: denoted by adding a decimal version. Maintainers may choose to include your PR in a patch release if it is related to a non-trivial and/or uncommon bug.
- Releases are delineated by:
* the version number,
* the ISO 8601 date (YYYY–MM–DD) and the time in UTC,
* and the name of the maintainer responsible for that release (in old cases the changelog author(s))
- The version number uses decimal versioning (e.g. v1.2 is an older version than v1.12), older releases use semantic versioning.
- Entries should be concise, in the present tense, and reference Adonis commands by their usage name (e.g. `:somecommand`).
- Maintainers will base the changelog entry off the title of your PR and may copyedit it for clarity.
- Maintainers may edit or reorganize entries before release publication.

## 6. Branching and Version Control

- All contributions must be based on the latest version of the `master` branch.
- Changes should not be based on the `release` branch.
- Outdated or conflicting code will not be merged.
- Conflicting code can be rectified using GitHub's web editor or through Git CLI.

## 7. Tooling and Development Environment

- We recommend using Rojo to sync with Roblox Studio.
- Developers should install Rojo via the [official documentation](https://rojo.space/docs/v7/getting-started/installation/) and avoid deprecated Marketplace versions.
- Aftman is used for dependency management.
- Rojo may be run via `rojo serve` or the VSCode plugin.

## 8. Documentation and Wiki

- Wiki contributions should focus on:  
  - Technical documentation of Adonis functions and variables.
  - Guidance for plugin developers.
  - Tutorials for new or inexperienced users.
- To contribute, contact a maintainer with your proposed addition for review.

## 9. Post-Merge Process

- Accepted contributions will be credited in the credits as:  
  `@GitHub YourGitHubUsernameHere`.
- If your first contribution is not properly credited, notify maintainers via Discord or PR comment.
- After merging, maintainers will conduct additional testing.
- Updated models are automatically published to Roblox once verified.

## 10. Contributor Recognition

- Accepted contributors may request the "GitHub Contributor" role in the [Discord server](https://discord.com/invite/H5RvTP3) and the "Contributors" rank in the [Roblox group](https://www.roblox.com/groups/886423).
- To request recognition, post your GitHub, Discord, and Roblox usernames in the [discussion thread](https://github.com/Epix-Incorporated/Adonis/discussions/433).
- Recognition is **not** granted for non-code contributions (e.g. .github changes, typo fixes).

## 11. Communication

- Questions, discussions, or clarification requests should be directed to the project’s [Discord server](https://discord.com/invite/H5RvTP3).
- Contributors are encouraged to engage constructively in PR discussions.

<div align="center">

<sub>Adonis Contribution Policy 2025</sub>

</div>
