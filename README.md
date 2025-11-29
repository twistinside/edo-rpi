# edo

Edo is a Raspberry Pi that lives in a closet and hosts Raspbian torrents. These scripts keep it updated and self-managing without manual SSH once the initial setup is done.

## Bootstrap install (run once)

1. Clone the repository to `/home/edo/rpi` on the Pi.
2. From the repo root run `./sh/bootstrap-install.sh`.
   - Copies `systemd/*.service` and `systemd/*.timer` files to `/etc/systemd/system/`.
   - Reloads systemd and enables/starts every timer found in `systemd/`.

## Automated updates

- `systemd/edo-git-update.timer` triggers `systemd/edo-git-update.service` every 30 minutes (and shortly after boot).
- The service runs `sh/git-self-update.sh`, which:
  1. Runs `git pull` in `/home/edo/rpi`.
  2. Checks for changes under `systemd/` between the previous and current HEAD.
  3. Re-runs `sh/bootstrap-install.sh` automatically if systemd units changed.

- `systemd/edo-bootstrap-install.timer` runs `sh/bootstrap-install.sh` every hour (and shortly after boot) to forcibly re-copy
  all versioned systemd units into `/etc/systemd/system/` and reload systemd. This keeps systemd in sync even if new timers
  are added without a prior Git pull or if a manual change drifts from the repo.

With the timer enabled, the Pi continually pulls the latest repo changes and re-applies any updated systemd units without further SSH access.

## Pilot log review configuration

- Pushover credentials are loaded from `$HOME/.pushover/config` (or the `CONFIG_FILE` override) and must provide `EDO_ACCESS_TOKEN` and `USER_KEY`.
- Pilot will source `$HOME/.openai/config` (or `OPENAI_CONFIG`) to populate `OPENAI_API_KEY` if it is not already set in the environment. The config file must define `OPENAI_API_KEY`.

## Replacing legacy cron jobs

The following timers mirror the previous crontab on the Pi:

- `systemd/edo-start-up.timer`: runs `/home/edo/rpi/sh/start-up.sh` once after boot with a 30s delay (replaces `@reboot`).
- `systemd/edo-rpi.timer`: runs `/home/edo/rpi/sh/rpi.sh` hourly (replaces `0 * * * *`).
- `systemd/edo-update.timer`: runs `/home/edo/rpi/sh/update.sh` daily at 01:00 (replaces `0 1 * * *`).
- `systemd/edo-reboot.timer`: runs `/home/edo/rpi/sh/reboot.sh` Fridays at 02:00 (replaces `0 2 * * 5`).
- `systemd/edo-free-space.timer`: runs `/home/edo/rpi/sh/free_space.sh` daily at 03:00 (replaces `0 3 * * *`).

All timers live in `systemd/` so they stay version-controlled and are picked up automatically by `sh/bootstrap-install.sh` and `sh/git-self-update.sh`.
