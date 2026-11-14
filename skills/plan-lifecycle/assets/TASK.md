# <unit>: <title>

- Plan ID: `<plan-id>`
- Status: todo
- Tier: <light|standard|heavy>
- Effort: <low|medium|high>
- Review: <yes|no>
- Depends on: <units that must be done first, or `None`>

## Goal

<What this unit delivers, as behavior: one coherent change that one agent finishes and one Reviewer reads in a
single pass, and that leaves the branch building and its tests passing.>

## Files

- <Files and symbols expected to change. Names, not line numbers.>

## Acceptance criteria

- <Observable result that proves the unit is done>

## Tests

- Unit tests: <the behavior this unit adds or changes and the cases its unit tests must cover, written in this
  unit; `None` only for a unit without behavior, with the reason>
- Commands: <commands to run for this unit and expected result>
- Test resources: <check to run on a shared resource and its lock name, or `None`>

## Notes

<What the Developer cannot cheaply rediscover and the plan file does not already say, or `None`>
