# Firefox setup

Files here reproduce my Firefox setup on a new machine or profile.

| File | What it is |
|---|---|
| `user.js` | The file my Firefox profile uses now: arkenfox user.js v144 (dated 21 April 2026) with my local changes |
| `my-ublock-backup_2026-11-02_21.02.00.json` | uBlock Origin 1.75.2 settings export (filter lists, whitelist, dynamic rules, user filters) |

## Local changes in user.js

Applied on top of the upstream arkenfox file. Search the file for these names.

- **Autofill and form capture on:** `browser.formfill.enable`, `signon.autofillForms`, `signon.formlessCapture.enabled`.
- **No clearing at shutdown:** `privacy.sanitize.sanitizeOnShutdown` = false. Clear-history flags reset to Firefox defaults (`privacy.clearOnShutdown_v2.*`, `privacy.clearSiteData.*`, `privacy.clearHistory.*`, `privacy.sanitize.timeSpan` = 1).
- **Restore previous session on start:** `browser.startup.page` = 3, `browser.startup.homepage` = `about:home`, `browser.sessionstore.privacy_level` = 0 (2 blocks session restore).
- **Disk cache on:** `browser.cache.disk.enable` = true.
- **Fingerprint resistance off:** `privacy.resistFingerprinting` = false, appended at the end of the file. With it on, the colonist.io game board rendered black. This removes fingerprint resistance for every site.

## Installing on a new profile

1. Quit Firefox.
2. Find the profile folder. Open `about:profiles` in Firefox, or list `~/.mozilla/firefox/`. Profile folder names are random, so don't hardcode one.
3. Copy `user.js` into that profile folder. Firefox reads it at every start.
4. Start Firefox. Check `about:support` → Profile Directory to confirm the right profile.
5. Install uBlock Origin from addons.mozilla.org if it isn't there yet.
6. In uBlock Origin, open the dashboard → Settings → Restore backup, and select the `my-ublock-backup_*.json` file. Only restore onto a fresh uBlock Origin install, because the backup overwrites its current settings.

Firefox does not read `user.js` from this folder on its own. It only takes effect once copied into a profile.

## Updating

- **arkenfox:** download the new `user.js` from https://github.com/arkenfox/user.js, re-apply the local changes above, and check the diff.
- **uBO backup:** use Settings → Back up in the uBO dashboard and replace the JSON file here. Keep the timestamp in the filename.

## Not covered

- Installing uBlock Origin automatically. That needs a Firefox `policies.json` file in `/etc/firefox/policies/`, which needs root.
- Extensions other than uBlock Origin.
