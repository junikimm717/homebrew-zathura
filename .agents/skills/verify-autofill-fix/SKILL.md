---
name: verify-autofill-fix
description: Reproduce the macOS 26 AutoFill completion-list CPU loop in zathura and verify a build fixes it. Use after changing patches/autofill-heuristics.diff, after upgrading zathura or gtk+3, or when zathura or WindowServer shows high CPU.
---

# Verifying the AutoFill loop fix

The loop only starts once a zathura window is **focused**. Launching zathura from a
background shell without focusing it shows 0% CPU even on a broken build, which is a
false pass.

## Remove user-level workarounds first

A `defaults` key hides the bug in any build, so clear it before testing:

```sh
defaults read zathura 2>/dev/null           # inspect
defaults delete zathura NSAutoFillHeuristicsEnabled 2>/dev/null
```

## Test procedure

Use any PDF (`$PDF`). For a dev build, set `BIN` to the absolute path of `build/zathura` and pass
`-p $(brew --prefix)/lib/zathura`.

```sh
BIN=$(brew --prefix)/bin/zathura
"$BIN" --fork "$PDF" >/dev/null 2>&1; sleep 1
pid=$(pgrep -nf "$BIN --fork")
osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $pid) to true"
sleep 8
ps -o %cpu= -p $pid                 # fixed: ~0; broken: ~145
OUT=$(mktemp)
sample $pid 2 -file "$OUT" >/dev/null 2>&1
grep -cE 'SPCompletionList|SPSafariPlatformSupport' "$OUT"   # fixed: 0
kill $pid
```

`osascript` needs Accessibility permission for the terminal. If it fails, ask the
user to click the zathura window instead.

## Interpreting results

- **Broken:** the main-thread stack shows `-[SPCompletionListRemoteViewController
  viewServiceDidTerminateWithError:]`, then `_setUpCompletionListViewController...`,
  then `NSRemoteView`. `/usr/bin/log stream --predicate 'process == "zathura"'` floods
  with `Error loading remote view controller ... NSXPCSharedListenerErrorDomain Code=2`.
- **A/B control:** to prove the test can catch the bug, temporarily run a build
  without the patch, or the stock upstream formula. It should hit about 145% CPU.
- **Still looping with the patch:** check that `zathura_macos_init()` actually runs.
  It must be compiled in (`__APPLE__` guard) and called before `gtk_init`. Then search
  the dyld shared cache for new AutoFill defaults keys, because Apple may have renamed
  it:
  `strings -n 14 /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e* | grep -E '^NSAutoFill.*Enabled$' | sort -u`
