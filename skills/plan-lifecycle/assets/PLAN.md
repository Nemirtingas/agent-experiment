# <plan-id>: <Plan title>

- Plan ID: `<plan-id>`
- Type: `<fix|feature|docs>`
- Status: pending
- Mode: automatic

## User goal

<State the requested outcome plainly. Preserve the user's intent without adding requirements.>

## Repository context

<Only what the Developers cannot cheaply rediscover: invariants, observations on shared test resources with
their date, decisions already taken. Name files and symbols, not line numbers. Distinguish facts from
assumptions.>

## Requirements and acceptance criteria

- Requirement: <specific requirement from the user or approved clarification>
  - Acceptance: <observable result that proves the requirement is met>

## Scope

- <Work included in this plan, as behavior>

## Non-goals

- <Related work explicitly excluded, or `None`>

## Dependencies

- <Plan ID and prerequisite, or `None`>

## Assumptions and open questions

- Assumptions: <assumptions and evidence, or `None`>
- Open questions: <decisions needed before validation, or `None`>

## Tasks

<The units run in this order, one agent each. A task too large for one agent and one review pass is split into
slices; the details of each unit are in its own file, seeded with `plan-lifecycle task`.>

- Task1: <what the task delivers>
  - Task1a: <what the slice delivers> (<tier>, <effort>, review <yes|no>)
  - Task1b: <what the slice delivers> (<tier>, <effort>, review <yes|no>)
- Task2: <what the task delivers> (<tier>, <effort>, review <yes|no>)

## Verification

- Unit tests: every unit that adds or changes behavior brings its own; see each unit file.
- Integration test: <the test that exercises the change end to end across its units, the acceptance criteria it
  covers and the unit that writes it; or why the change has nothing to integrate>
- Validation by the Lead: <what the Lead runs and observes on the finished branch before the merge: the
  commands, the integration test, each acceptance criterion as the user would see it>
- Test resources: <checks to run on a shared resource before the merge and who runs them, or `None`>
- Final review: <yes|no, with the reason when no>

## Risks and compatibility constraints

- <Known risk or constraint and its effect, or `None`>

## Handoff notes

<Important details for the Developers and Reviewers not stated above, or `None`>
