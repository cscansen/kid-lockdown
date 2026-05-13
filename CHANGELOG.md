# Changelog

## [1.1.0] - 2026-05-13

### Changed
- **Expanded HIDE_ALWAYS** — added comprehensive lockdown for `restricted` profile:
  - All Cinnamon settings panels (26 entries) — settings, display, network, keyboard, mouse, privacy, screensaver, startup, themes, etc.
  - Dangerous admin tools: `lightdm-settings`, `gufw`, `gnome-online-accounts-gtk`, `fingwit`, `webapp-manager`
  - Text editors: `org.x.editor`, `vim`
  - System monitors/diagnostics: `org.gnome.SystemMonitor`, `gnome-system-monitor-kde`, `org.gnome.PowerStats`, `org.gnome.seahorse.Application`
  - Bluetooth managers: `blueman-adapters`, `blueman-manager`
  - File/archive tools: `org.gnome.baobab`, `org.gnome.FileRoller`, `org.x.Warpinator`, `thingy`, `bulky`
  - Misc: `gucharmap`, `mate-color-select`, `onboard`, `org.freedesktop.IBus.Setup`, `org.gnome.font-viewer`, `simple-scan`, `system-config-printer`, `transmission-gtk`
  - Browsers: `firefox` (Chrome is the controlled/locked browser)

## [1.0.0] - 2026-05-11

### Added
- **Initial release** — split out from `net-safety` repo as a standalone script.
- **App hiding** — hides Mint system tools, LibreOffice suite, and Thunderbird from the kid account via per-user `NoDisplay` overrides. Idempotent; admin account is unaffected.
- **Google Docs / Google Sheets launchers** — installs Chromium if absent, then creates `.desktop` entries system-wide and on the kid's desktop. Opens in Chromium `--app=` mode (standalone window, no browser chrome). Works offline once "Make available offline" is enabled in Google Drive settings.
- **Age-based profiles** — accepts a `profile` argument (`restricted` / `tween` / `teen`). `restricted` is fully implemented (age ~6). `tween` and `teen` are scaffolded and fall back to `restricted` until implemented.
- **Silent auto-updates** — enables `mintupdate-automation-upgrade.timer` and `mintupdate-automation-autoremove.timer` so the OS patches daily without GUI interaction.
