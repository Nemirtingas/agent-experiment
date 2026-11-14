# <unit> evidence

- Plan ID: `<plan-id>`
- Unit: `<unit>`

## Implementation

<Written by the Developer.>

- Agent: <provider/model, effort>
- Commits: <first and last revision of the unit>
- Summary: <what changed, in two or three lines>

## Tests

- Unit tests: <the tests added or changed for this unit and what they cover, or `None` with the reason>
- `<command>`: <result, with the lines of output that prove it, not the whole log>
- Test resources: <check run under resource-lock and its result, or `None`>
- Not verified: <what could not be run and why, or `Nothing`>

## Acceptance

- <criterion of the unit file>: <met, and what shows it>

## Review

<Written by the Lead. For a unit with `Review: no`: `Not reviewed`, and what the Lead checked before closing it.
For a reviewed unit, one entry per pass from the Reviewer's reports: the reviewing provider/model, each Required
finding and how it was closed, the Optional findings; the last entry ends with the approving pass's Reviewed-by
line, alone on its line, which `plan-lifecycle close` requires.>
