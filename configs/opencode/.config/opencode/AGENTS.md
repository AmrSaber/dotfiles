## Behaviour
- Read the project's README and/or contribution guide first, before anything else.
- Prefer `mise` on projects that use it (`mise.toml` / `mise.local.toml`): its tasks respect project conventions and give the best output, so favour e.g. `mise test` over a manual test command — unless you need options the task doesn't expose.

## Code Style
- Order code for human readability: entry point / main function first, then helpers in roughly the order they're first called (DFS from the entry point).
- Principle of locality: define constants and variables close to where they're used, not globally or at the top of the function.

## Long-running / Verbose Commands
Never block the session on a long command. Run it detached, send its output to a log, then poll that log on a fixed interval.

**Start it in the background.** Redirect both streams to `/tmp/<name>.log` and record the PID:
```bash
<command> > /tmp/<name>.log 2>&1 &
echo "PID: $!"
```

**Periodically poll for the status**, polling interval can vary depending on the expected runtime of the command, it can be any of (1, 2, 5, or 10 minutes) and it can also be overridden by the user if they want more periodic updates or if they only care about the end result. Sleep and inspect in a single call, so the turn never sits idle:
```bash
sleep 120 && <check-command>
```
Where `<check-command>` could be:
- Checking the status of the process via `ps`
- Checking the log file with `tail` or `cat` (if limited output is expected)
- Any other indication of the command's processing and progress. No hard rule here, do whatever is suitable to get the command's status

A few notes:
- **Grep for signals; don't dump the log.** Pull only the lines that show progress, success, or failure. Tailing thousands of lines burns context for nothing.
- **Keep polling until the job finishes.** Never go idle while a background job runs. With nothing else to do, keep sleeping and re-checking. Use the gaps for other useful work when there is any.
- **Expect buffered output.** Some tools (Jest, for one) print nothing until every suite ends, so an empty log does not mean the job is stuck. Confirm progress from external state instead — the process table, AWS resources, ...
- **Report deltas, not heartbeats.** Speak up when the state changes; stay quiet when it hasn't.
- **Clean up afterwards.** Kill orphaned child processes when aborting a run, and delete the log when done.

## Writing Guideline
Use these guidelines in all your writings (files, docs, comments, commit messages, PR descriptions, ...), they apply to any persistent text being written in any context.

### General style
Applies to every kind of durable writing.
- **Short sentences and paragraphs.** Aim for ≤25 words per sentence (not a hard limit); keep paragraphs short — readers skim. Convert a long sentence to a list or table when it helps.
- **Active voice, strong verbs.** Prefer the specific/concrete to the vague/abstract; avoid "to be"/"to have" where a stronger verb fits. "Choose encryption", not "encryption should be chosen".
- **Tighten prose.** "in order to" → "to"; "have the ability/opportunity to" → "can"; "must be able to" → "must". Delete filler: "note that", "please", "you should", "whether or not" → "whether".
- **Avoid nominalizations** — turn the noun back into a verb ("your source doesn't redeploy", not "no redeployment of your source occurs").
- **Goal first, then task.** "To enable X, do Y" — not "Do Y to enable X".
- **Lists to break up dense text.** Complete the introductory sentence before the list; keep items parallel; don't split one sentence across bullets.
- **Global English (write for ESL readers and translation).** Use complete sentences; use one term consistently and define new ones; keep adjectives/adverbs next to what they modify (watch _only_, _successfully_, _automatically_); add optional clarifiers (_that_, _who_, _a/an/the_). Prefer precise words: _after_ (not _once_), _might_ (not _may_), _because_ (not _since_/_as_), _although_ (not _while_), _can_ (not _could_), _compared to_ (not _vs._). Watch ambiguous "-ing"/"-ed" words; add a determiner to disambiguate.
- **No jargon.** "leverage" → "use"; "utilize" → "use"; "performant" → "high-performing"; "payload" → the specific thing; "best-in-class"/"enterprise-grade" → drop and say what it does.
- **No Latinisms.** "e.g." → "for example"; "i.e." → "that is"; "via" → "through"/"by using"; "etc." → "and so on"; "vs." → "compared to". Exception: _per_ is fine in technical units (QPS, per-Region).
- **Modal verbs.** _can_ = capability; _must_ = requirement; _might_ = possibility (not _may_). For recommendations use "we recommend" or "consider", not "should". Prefer the imperative for required actions ("Set the value", not "You should set the value").
- **Tense and tone.** Present tense (future only for genuinely later events). Direct, friendly, concise — not chatty, not bossy. Contractions are fine (_it's_, _don't_); avoid future-tense contractions (_I'll_).
- **Capitalization.** Sentence case for titles and headings; title case for product/service names; lowercase for feature names. File formats in caps (HTML, PDF); actual filenames lowercase (`index.html`).
- **Acronyms.** Spell out on first use — "spelled-out term (ACRONYM)"; skip for common ones (AI, API, JSON, URL, PDF); choose "a"/"an" by pronunciation.
- **Dates and numbers.** Sortable `YYYY-MM-DD`; human-readable "October 1, 2022"; no ordinals ("January 1", not "1st"); time zones like UTC-8.
- **No hard paragraphs**: don't hard-wrap paragraphs — one long line per paragraph, let the editor soft-wrap. Hard breaks only at real paragraph or list-item boundaries..

### Customer-facing / external docs
Adds to general style for anything a customer or external reader sees.
- **Speak to the reader as "you"** (second person). Avoid "developer"/"user" except where unavoidable (e.g. "IAM users").
- **Don't say a service "allows / enables / lets" the customer.** Write "With X, you can…" or "Use X to…". (You may _enable_/_disable_ a feature or setting — never a person.)
- **Document the task, not the feature.** Headings name what the reader does ("Converting phone numbers into strings"), not the API name.
- **Write from the customer's point of view**, and give a real introductory paragraph (why you'd do this, not just a restatement of the title).
- **Worldwide audience.** Global English, inclusive language, and accessibility matter more here — no idioms, no culturally specific references.
- **No overpromising.** Don't claim outcomes you can't stand behind; if it's a guide, apply the evidence rule in `field-guide-authoring`.

### Internal docs
Engineer-to-engineer material (runbooks, design docs, team wikis, internal guides).
- Keep all of general style — concision, active voice, structure, and precise words still apply.
- Register can be **more direct and assume shared context**; team-shared jargon is fine, but define anything non-obvious.
- **"We"/"the team" is acceptable**, and the customer-voice rules (avoiding "allows/enables") don't apply — spend no effort there.
- **Lead with the decision or outcome**, put the rationale (why) next to it, and point volatile specifics (versions, IDs) at their source rather than restating them.

### Code comments & docstrings
- **Explain WHY, not what or how** — the code already shows what it does. A one-liner beats a paragraph; prefer none over noise.
- **Describe what the code IS, not what it WAS** — no history/migration narration ("previously…", "renamed from…"); that belongs in commit messages.
- **Docstrings** are goal-first and imperative ("Return the parsed config", "Compute the weighted score").
- **Commit/PR messages** describe the change and its intent; this is where the historical "why we changed it" belongs.
- **OK to soft break** comments to conform to line limit imposed by linters.
- **Be sparing**: prefer none over excessive. Add a comment only when the rationale is genuinely non-obvious; a short one-liner beats a paragraph. Default to fewer.
