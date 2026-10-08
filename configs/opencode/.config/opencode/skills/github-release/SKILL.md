---
name: github-release
description: Create a new release on Github
---

## What I do
- Make sure to `fetch` all tags from origin repo
- Make sure work tree is clean, if not ask user what to do about it
- Get all the updates since the last release
- See the description of the previous 2-3 releases to understand the format of the description, if they are drastically different, favour more recent releases
- Confirm the description with the user
- Propose a version bump following semantic versioning, confirm with user before committing to the new version
- If all is well, create a new release on Github using `gh` tool
- Unless asked otherwise, create a draft release
- Brief the user with what's been done, specifying whether you've created an actual release or draft release

# Note
**You MUST always create the GitHub release yourself.** This holds *even when CI is configured to create a release on tag push*. Do not skip it, do not defer to the pipeline, and do not even ask the user whether to create one — creating the release with the confirmed body and settings is mandatory and non-negotiable. CI automation is not a substitute; assume it may be absent, misconfigured, or produce a body other than the one confirmed. The confirmed body is the source of truth, and it is your job to publish it.

## When to use me
When user asks to create a github release, or says it's release time.
