<div align="center">

# 📜 Adonis Contribution Guidelines
*Updated on 2022-06-25 18:35 UTC by Expertcoderz*

<img src="https://user-images.githubusercontent.com/81153405/175760639-fc3b2352-8066-48cc-b2e6-2ea0ad69e33e.png">

Adonis is an ever-expanding, frequently updated, slightly complicated, system. To keep Adonis functional and somewhat readable rather than a tangled mess, here are some guidelines in the form of an FAQ to consider before submitting a pull request:

## Q: Who's in charge of handling pull requests (PRs)?

**A:** [@Sceleratis](https://github.com/Sceleratis), as well as our community maintainers (viz. [@Coasterteam](https://github.com/Coasterteam), [@joritochip](https://github.com/joritochip) and [@Expertcoderz](https://github.com/Expertcoderz)) are responsible for the final approval and merging of PRs, and the publishing of releases from time to time.

Anyone in the community may submit code reviews for PRs and make discussions on the PR's page (or in the Discord server).

Maintainers may manage PR labels or edit PR titles and descriptions where beneficial to conform to the standards described below.

## Q: How should PRs be titled and formatted?

**A:** **Title:** The title of a PR should be in the present tense, and equivalent to a concise statement describing what was added, changed or removed by the PR: "Add XXX setting"; "Add :somenewcommand"; "Fix for :somecommand not doing XXX"; "Fix for :somecommand to account for XXX"; ":somecommand now does XXX"; "Add confirmation prompt for :somecommand"9

A short explanation/clarification may be appended to the title, and should be included in the PR involves making a change with a rationale that users may not understand: "Add confirmation prompt for :somecommand to prevent XXX"

Note that Adonis commands are _always_ referenced by their prefix and common usage name (":somecommand"/":somecmd"), and not anything else including their internal index ("SomeCommand"). This is to ensure consistency and easy comprehension by normal Adonis users.

**Description:** The description of a PR should be comprehensive and either describe, or list and describe the specific additions, changes, and/or removals made by the PR, and their full rationale.
  
ℹ️ **The above rules do not apply to individual commit names and descriptions.**

You may optionally include relevant [label(s)](https://github.com/Sceleratis/Adonis/labels) in your PR to classify it. (Maintainers will add the labels otherwise after reviewing your PR.)

## Q: What can I contribute?

**A:** Anything within reason! Contributions can be to Adonis itself or the wiki (or both!) As long as your addition or change is useful and doesn't break something, and makes sense (while not violating ROBLOX's rules) it will *probably* be merged. However, something may occasionally be deemed unnecessary or incomplete, at which point a comment will be made on the PR for you to respond to or amend your code (or just so you know the maintainers' reasoning.)

## Q: What *can't* I contribute?

**A:** Anything that violates ROBLOX's rules (as in, anything that could get Adonis or games using Adonis in trouble) is not allowed for obvious reasons. Additionally, please do not submit any form of obfuscated code as they have no place in the open-source project that Adonis is.

There is a very clear/obvious difference between unavoidably complex code and intentionally complicated code. Maintainers are certain to check all file changes before merging and can *usually* spot something abnormal quickly.

## Q: Is there a style guide for writing code?

**A:** Not really, but we would normally try to follow the format of the other existing code in the module we are editing, as well as the [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/) where applicable. Also, be sure to use US English spellings for both code variable names and user-facing text.

## Q: What are some things I should watch out for when submitting my changes?

**A:** Bugs! 🐛 If you are submitting code changes, please be sure to TEST THEM BEFORE SUBMITTING THEM! No one would be quite happy to spend an hour debugging your contribution when merging changes into the model.

Also, try to double-check any text for spelling issues. Some of us frequently make typos/mistakes, so it's not a huge deal if you miss something, but a wholly incoherent string of letters and words is not acceptable.

Finally, ***be sure to make file changes based on the latest version of the ``master`` branch, not ``release``!*** Outdated and conflicting code is often a pain to deal with.

## Q: What can I contribute to the Wiki?

**A:** Wiki contributions should focus on technical information, such as what various functions and variables do/are for and how to use them correctly when developing plugins for Adonis. Information about Adonis and useful tutorials for new or inexperienced users is also acceptable (and much welcomed.)

## Q: My contribution was accepted. Now what?

**A:** After handling the merge, a maintainer will also add you to the credits list as "@GitHub YourGitHubUsernameHere" if it's your first contribution. If we forget to do this, and you notice, just us me know (via Discord or comment on the PR itself) and we'll fix it.

Once in a while after changes are merged, some quick testing will be done by a maintainer to make sure everything works correctly. Once that's done, the updated models will be published to ROBLOX by an automated process, after which all new servers will be running the latest version of Adonis.

## Q: How do I get the "GitHub Contributor" role and group rank?

**A:** After your contribution is accepted, post your Discord & ROBLOX usernames into the discussion thread (<https://github.com/Sceleratis/Adonis/discussions/433>). You will be given the "GitHub Contributor" role in the Discord server and the "Contributors" rank in the ROBLOX group (Epix Incorporated) by a maintainer, assuming you are a member of the server and group respectively.

ROBLOX group: https://www.roblox.com/groups/886423

Discord server: https://discord.com/invite/H5RvTP3

<hr>

### That's all, folks!

Feel free to make inquiries on our Discord server.
  
<sub>Adonis Contribution Guide 2022</sub>

</div>
