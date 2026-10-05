---
name: github-release
description: Use when asked to create a new release on Github
---

# Releasing to GitHub

Follow these steps in order. Steps 1–4 require user confirmation before proceeding; steps 5–6 are executed once confirmed.

1. **Check the last release.** Look up the most recent published release/tag (`gh release list`, `gh release view`, or git tags) to establish the current version and note the format of previous release bodies.

2. **Confirm the new version.** Propose a version yourself (semver-appropriate to the changes since the last release) and confirm it with the user.

3. **Confirm the release body.** Draft a comprehensive body and confirm it with the user. Base the draft on:
   - the format/style of previous releases, and
   - the actual changes since the last release (`git log <last-tag>..HEAD`, merged PRs).

4. **Confirm draft vs. published.** Ask the user whether this is a draft release.

5. **Tag and push.** Create the tag and push it.

6. **Create the GitHub release — always, immediately.** Right after pushing the tag, create the release on GitHub (`gh release create`) with the confirmed body and draft flag.

## The rule that matters most

**You MUST always create the GitHub release yourself.** This holds *even when CI is configured to create a release on tag push*. Do not skip it, do not defer to the pipeline, and do not even ask the user whether to create one — creating the release with the confirmed body and settings is mandatory and non-negotiable. CI automation is not a substitute; assume it may be absent, misconfigured, or produce a body other than the one confirmed. The confirmed body is the source of truth, and it is your job to publish it.
