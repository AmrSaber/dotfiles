---
name: code-review
description: Guidelines for code review on Github, Gitlab, or any other similar place.
---

## General Guidelines
- Pull the full context around the code review, including (title, description, comments, threads, existing reviews, ...) as well as the code change itself
- When reviewing the changes use the existing codebase for reference when possible

## How to Review
- Code correctness is a must
  - The code must satisfy the purpose of the code review mentioned in the description (and any linked tickets)
  - The code must not have any logical errors
- Look for simplification opportunities
  - Can the changes be made simpler?
  - Can we use/reuse any existing components?

## The Use of 3rd-party code
- Using 3rd party code is generally fine, but the judgement is per-case
- If the dependency already exists in standard-lib then standard lib must be used
- If the dependency is for a trivial task, then favour writing the logic

For highly specialised logic with high testing and maintenance cost (e.g. cron-job syntax validation), favour using a trusted 3rd party dependency.

## How to Report Findings
- Flag any correctness comments as critical
- Simplification is high priority although not always blocking
  - Small simplifications can be nits
  - Simplification of core part of the change or a change that would have significant impact can be critical
- Any change that would have a significant impact in general is blocking
- It's fine to flag nits but they are not blocking and don't focus too much on them
