---
name: update-zathura
description: Sync this fork with upstream homebrew-zathura, bump zathura/girara/plugin versions, and refresh patches/autofill-heuristics.diff when it no longer applies. Use when asked to update or upgrade zathura, pull upstream, or when `brew upgrade` fails on a patch.
---

# Updating zathura in this fork

Work in `~/Documents/repos/homebrew-zathura` (remotes: `origin` = junikimm717 fork,
`upstream` = homebrew-zathura). Read `AGENTS.md` first for the invariants.

## 1. Pull upstream

```sh
git fetch upstream
git merge upstream/master
```

Conflicts usually show up in `Formula/zathura.rb` or `Formula/zathura-*.rb`. Resolve
them so that:
- `zathura.rb` still has the `autofill-heuristics.diff` patch block after
  `mac-integration.diff`, and the `inreplace` setting `'#{HOMEBREW_PREFIX}/lib/zathura'`.
- Each plugin still uses `inreplace ... "'#{lib}/zathura'"` and has **no**
  manual-symlink caveat.

## 2. Bump versions (if upstream hasn't)

Edit `url` in the formula to the new tag from `https://github.com/pwmt/<project>/tags`,
then refresh the hashes:

```sh
cd sync && uv run main.py
```

## 3. Check that our patch still applies

```sh
V=<new zathura tag>
rm -rf /tmp/zcheck && git clone -q --depth 1 -b $V https://github.com/pwmt/zathura /tmp/zcheck
cd /tmp/zcheck
patch -p1 < ~/Documents/repos/homebrew-zathura/patches/mac-integration.diff
patch -p1 --dry-run < ~/Documents/repos/homebrew-zathura/patches/autofill-heuristics.diff
```

If it fails, regenerate it against the new source:

1. `git add -A && git commit -qm base` (this commits the source with
   `mac-integration.diff` applied).
2. Re-create `zathura/macos.h` and `zathura/macos.m` from the old diff.
3. In `zathura/main.c`, add `#ifdef __APPLE__ #include "macos.h"` and call
   `zathura_macos_init();` right before `gtk_init(&argc, &argv);`.
4. In the darwin block of `meson.build`, add `add_languages('objc', native: false)`
   and `dependency('appleframeworks', modules: ['Foundation'])`. Also add
   `sources += files('zathura/macos.m')` under a darwin guard, after
   `sources += zathura_resources`.
5. `git add -A && git diff --cached > ~/Documents/repos/homebrew-zathura/patches/autofill-heuristics.diff`
6. `meson setup build && ninja -C build` must succeed.
7. Also dry-run `no-titlebar.diff` on top, so the optional build still works.

Then update the patch's `sha256` in `Formula/zathura.rb`.

## 4. Install and verify

```sh
git commit -am "Bump zathura to $V" && git push origin master
brew update && brew upgrade junikimm717/zathura/zathura junikimm717/zathura/zathura-pdf-poppler
zathura --version   # plugins must be listed under /opt/homebrew/lib/zathura/
```

Then run the `verify-autofill-fix` skill. Don't call the update done until it shows
about 0% CPU with the window focused.

If upstream ever fixes the plugin path or the AutoFill loop itself, prefer upstream's
fix and drop ours. Say so explicitly in the commit.
