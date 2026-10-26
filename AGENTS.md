# AGENTS.md

Personal fork of [homebrew-zathura/homebrew-zathura](https://github.com/homebrew-zathura/homebrew-zathura),
tapped as `junikimm717/zathura`. It carries two changes on top of upstream:

1. **macOS 26 AutoFill CPU loop fix** (`patches/autofill-heuristics.diff`).
2. **Version-independent plugin directory**, so plugins survive upgrades without
   manual symlinks.

Keep both working whenever you touch this repo.

## Layout

| Path | What it is |
|---|---|
| `Formula/zathura.rb` | zathura itself. Applies patches, rewrites the plugin dir. |
| `Formula/zathura-*.rb` | Plugins (`cb`, `djvu`, `pdf-mupdf`, `pdf-poppler`, `ps`). |
| `Formula/girara.rb`, `Formula/synctex.rb` | Libraries. Note that `girara` currently resolves from homebrew/core when installed as a dependency. |
| `patches/mac-integration.diff` | Upstream tap patch: zsh completion `.so` to `.dylib`, plus `mac-integration.c`. It removes the `GTKOSXAPPLICATION` define and gates its code on `MAC_INTEGRATION`, which nothing defines, so that integration code is effectively dead. |
| `patches/autofill-heuristics.diff` | Our patch, applied **after** `mac-integration.diff`. |
| `patches/no-titlebar.diff` | Optional (`--with-no-titlebar`), applied after ours. |
| `convert-into-app.sh` | Builds a `.app` bundle and copies plugins from `<plugin keg>/lib/zathura/`. |
| `sync/` | Upstream's tool for refreshing `sha256`s after a version bump (`uv run main.py`). |
| `.agents/skills/` | Task playbooks. `.claude/skills` and `CLAUDE.md` are symlinks into this setup. |

## Invariants: don't break these

**Plugin directory contract.**
- `zathura.rb` rewrites `join_paths(prefix, plugindir)` in `meson.build` to
  `'#{HOMEBREW_PREFIX}/lib/zathura'`. That makes the compiled-in `ZATHURA_PLUGINDIR`
  `$(brew --prefix)/lib/zathura`, not the versioned keg.
- Every plugin formula rewrites `zathura.get_variable(pkgconfig: 'plugindir')` to
  `'#{lib}/zathura'`, so its dylib lands in `<keg>/lib/zathura/` and `brew link` exposes
  it at `$(brew --prefix)/lib/zathura/`.
- Never reintroduce "symlink this dylib manually" caveats. If you add a plugin
  formula, follow the same pattern.
- `convert-into-app.sh` depends on the `<keg>/lib/zathura/lib<name>.dylib` location.

**AutoFill patch.**
- `zathura/macos.m` calls `registerDefaults:@{@"NSAutoFillHeuristicsEnabled": @NO}` from
  `zathura_macos_init()`. `main.c` calls it right before `gtk_init`.
- It is guarded by `#ifdef __APPLE__`, **not** `GTKOSXAPPLICATION`, because
  `mac-integration.diff` deletes that define.
- The key must be `NSAutoFillHeuristicsEnabled`. `NSAutoFillHeuristicControllerEnabled`
  (the key Ghostty and cmux use) was tested and does **not** stop the loop for GTK.
- `meson.build` gets `add_languages('objc', native: false)` and a Foundation framework
  dependency in the darwin block. This coexists with `no-titlebar.diff`, which adds
  `objc` to `project()`.

**Patch order** in `zathura.rb`: `mac-integration.diff`, then `autofill-heuristics.diff`,
then (optionally) `no-titlebar.diff`. Each diff is written against the result of the
previous ones.

## Background on the bug

On macOS 26, focusing a zathura window makes AppKit's AutoFill heuristics request the
`com.apple.SafariPlatformSupport.Helper` completion-list view service for GDK's text
input view. Loading fails with `NSXPCSharedListenerErrorDomain Code=2`, and
`-[SPCompletionListRemoteViewController viewServiceDidTerminateWithError:]` immediately
re-requests it. zathura and WindowServer each sit at about 145% CPU, and the log
produces tens of thousands of lines per second.

- Wrapping zathura in a `.app` bundle does not help.
- The root cause is likely in GTK3's macOS backend, so other GTK3 apps on macOS 26
  are probably affected too.

## Working on formulae

```sh
# Edit in a git clone of this fork, not in the Homebrew-managed copy at
# $(brew --repo junikimm717/zathura). After pushing to origin/master:
brew update && brew reinstall junikimm717/zathura/zathura
```

- Homebrew 7 needs tap trust. Trust specific formulae, not the whole tap:
  `brew trust --formula junikimm717/zathura/<name>`.
- Patches are referenced as `file://#{__dir__}/../patches/<name>.diff` with a `sha256`.
  After editing a patch, recompute it with `shasum -a 256 patches/<name>.diff` or
  `cd sync && uv run main.py`.
- Uninstalling zathura makes brew autoremove its build deps (meson, ninja, sphinx-doc).
  They come back automatically on the next build.
- To check the install, run `zathura --version`. It should list each plugin with a path
  under `$(brew --prefix)/lib/zathura/`.

## Environment gotchas (macOS, zsh)

- `log` is a zsh builtin. Use `/usr/bin/log show` and `/usr/bin/log stream`.
- `sudo` needs a TTY. It fails silently-ish when run from a non-interactive agent
  shell, so hand it to the user.
- Quote globs in `grep --include='*.c'` (zsh `nomatch`).

## Skills

- `.agents/skills/update-zathura/`: sync with upstream, bump versions, refresh patches.
- `.agents/skills/verify-autofill-fix/`: reproduce the CPU loop and prove a build fixes it.
