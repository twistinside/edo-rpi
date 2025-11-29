# Agent Instructions for edo-rpi

## Scope
These instructions apply to the entire repository. If a more specific `AGENTS.md` is added to a subdirectory, follow the most specific guidance for files within that scope.

## Expectations
- Preserve internal consistency across the repository. When modifying or adding files, ensure that related scripts, systemd units, and documentation point to the same paths, configuration files, and shared helpers.
- Keep scripts aligned with `sh/common.sh` conventions (environment setup, logging, and helper functions) whenever they rely on shared behaviors.
- Verify that job definitions (e.g., systemd services/timers) reference the correct target scripts and absolute paths used elsewhere in the repo.
- When touching configuration references (e.g., Pushover or OpenAI config locations), confirm the same paths and variable names are used across all consumers.

## Required Audit for Every Change
Perform these checks before completing any work in this repository:
1. Review scripts and systemd units for path consistency (notably `/home/edo/rpi` and `sh/common.sh`).
2. Confirm that shared scripts invoked by jobs exist and are executable.
3. Ensure documentation matches the effective paths and behaviors of scripts and units.
4. If new files or paths are introduced, update all dependent scripts and timers to use them.
5. Note any findings or confirmations in the summary of your final response.

Follow this audit after making changes to validate the repository remains coherent.
