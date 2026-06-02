---
name: hbuilderx-automation
description: Automate HBuilderX CLI workflows for Uni-App X projects. Use whenever a user asks to compile, run, debug, or verify Uni-App X/HBuilderX Web, H5, Android, iOS, Harmony, device logs, screenshots, or says to keep fixing until HBuilderX passes. Drives the local HBuilderX CLI, interprets compile logs, and turns recurring compiler failures into tests or coding rules.
---

# HBuilderX Automation

Use this skill to control HBuilderX from the terminal for Uni-App X projects, especially when the user wants Web/H5 and App builds verified rather than only Node tests.

## CLI Discovery

Prefer the macOS bundled CLI when present:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli
```

If that path is missing, locate HBuilderX before giving up:

```bash
mdfind 'kMDItemFSName == "HBuilderX.app"'
```

Confirm available commands with:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli help
```

## Compile Commands

Use absolute project paths. For `mms-unix`, the source-of-truth Android compile command is:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch app-android --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix --compile true --continue-on-error false --cleanCache false
```

For Web/H5 compile verification:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch web --project /absolute/path/to/project --compile true --continue-on-error false --browser Built
```

For `mms-unix`, keep the project runbook close at hand:

```text
/Users/shanpengnian/MyWork/mms-cashier/mms-unix/docs/uni-app-x-hbuilderx-runbook.md
```

Use `--compile true` when the goal is compiler verification without requiring a connected device. Use `--continue-on-error false` so the first real compiler error is precise and actionable. Keep `--cleanCache false` during tight debug loops; switch to `--cleanCache true` once after confusing cache behavior or before final verification.

## Workflow

1. Run the project’s fast local tests first if they exist.
2. Run HBuilderX Web/H5 compile if the project targets H5.
3. Run HBuilderX App compile for the requested platform, usually `app-android`.
4. If the compile fails, read the first `[plugin:uni:app-uts] 编译失败` block and fix that exact root cause.
5. Add or update a focused regression test or static compatibility guard for every compiler pattern fixed.
6. Re-run the focused tests and the HBuilderX compile command that failed.
7. Repeat until HBuilderX prints a successful compile marker and no red compiler error remains.

For `mms-unix`, also verify the project-specific runbook and doc guard when changing HBuilderX/Uni-App X behavior:

```bash
npm test -- tests/mms-unix-component-upgrade-doc.test.js
```

## Result Interpretation

Treat these as success markers:

- `项目 <name> UTS编译完毕。`
- `ready in <duration>ms.`
- For Web/H5, a Vite URL plus `UTS编译完毕`.

Do not treat a final red `已停止运行...` as a compile failure by itself when `--compile true` was used and the log already contains `UTS编译完毕`. In compile-only mode, HBuilderX may stop the run session after compilation.

Treat these as failures:

- `[plugin:uni:app-uts] 编译失败`
- `error:` lines with file, line, and column references
- missing `UTS编译完毕` after a compile command exits
- CLI process exit with an error before compilation finishes

Treat warnings as follow-up work, not as a failed compile unless the user explicitly requires warning-free output. Warnings that say “This will become an error in a future release” should be turned into coding rules or scheduled cleanup.

## Web/H5 Port Handling

HBuilderX Web usually tries `http://localhost:5173/`, but if that port is occupied it may switch to `5174` or another free Vite port. Always report and test the URL printed by HBuilderX instead of assuming `5173`.

If the in-app browser shows `Failed to connect to /127.0.0.1:8002`, first treat it as a possible HBuilderX internal debug-service disconnect. Re-run Web/H5, use the newest printed Vite URL, then inspect the route such as `/#/pages/order/order`.

## Android Orientation Checks

For Uni-App X Android landscape apps, do not rely on one manifest field. Source config should include both startup orientation and global page orientation:

- `manifest.json`: `app.screenOrientation`, `app-android.screenOrientation`, and `app-ios.screenOrientation` as `['landscape-primary']`.
- `pages.json`: `globalStyle.pageOrientation` as `landscape`.

After Android compile, inspect the generated manifest before declaring orientation fixed:

```bash
node -e "const fs=require('fs'); const m=JSON.parse(fs.readFileSync('mms-unix/unpackage/dist/dev/app-android/manifest.json','utf8')); console.log(JSON.stringify({screenOrientation:m['app-android']?.screenOrientation, uniAppX:m['app-android']?.distribute?.['_uni-app-x_'], globalStyle:m['app-android']?.distribute?.globalStyle}, null, 2));"
```

Expected values include `screenOrientation: ['landscape-primary']`, `_uni-app-x_.pageOrientation: 'landscape'`, and `globalStyle.pageOrientation: 'landscape'`.

## Useful HBuilderX Commands

Open/import a project:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli project open --path /absolute/path/to/project
```

List imported projects:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli project list
```

List Android devices:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli devices list --platform android
```

Run to Android device instead of compile-only:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch app-android --project /absolute/path/to/project --deviceId <device-id> --compile false --native-log true --continue-on-error false
```

Read latest Android build/runtime logs:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli logcat app-android --project /absolute/path/to/project --mode lastBuild
```

Capture an Android screen after a successful device run:

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli screencap app-android --project /absolute/path/to/project --deviceId <device-id> --saveFile /absolute/path/screenshot.png --fullPage false
```

When a run-to-device command compiles but does not print the app startup marker, do not leave the session running indefinitely. Check `devices list`, read `logcat --mode lastBuild`, and try `screencap` only after the project is confirmed running on the target device.

## Uni-App X Debugging Heuristics

When HBuilderX reports App UTS/UVue errors, prefer these fixes before larger rewrites:

- Replace truthy checks on non-boolean values with explicit comparisons: `text !== ''`, `value != null`, `list.length > 0`.
- Avoid comparing boxed or mixed numeric types with identity equality when HBuilderX warns about `Number`, `Int`, or implicit boxing.
- Avoid destructured event-handler parameters in `.uvue` methods. Accept `event: any | null`, cast to `UTSJSONObject`, then read `event['detail']`.
- Normalize `Any?` template prop values in helper functions before returning strings, objects, or booleans.
- Avoid object spread and array spread in typed state updates when HBuilderX warns about incompatible generic upper bounds. Build typed arrays and typed state objects explicitly.
- If native logs show `ClassCastException: AppConfig cannot be cast to UTSJSONObject`, fix the bridge boundary. Build and pass a real `new UTSJSONObject()` tree instead of sending a typed business config object into code that indexes it as `UTSJSONObject`.
- Avoid runtime orientation locking through `plus as any` or `uni as any` in `App.uvue`; prefer manifest plus `pages.json.globalStyle.pageOrientation` for Uni-App X Android landscape projects.
- Avoid `Number(value)` and `String(value)` constructors in App UTS; use `parseFloat('' + value)` and `'' + value`.
- Avoid `unknown`, `undefined`, inline object literal types, generic object-literal methods, and TypeScript-only type predicates in `.uts` files.
- For style objects, use `UTSJSONObject` with kebab-case CSS keys.

## Final Verification Report

When reporting back, include:

- HBuilderX version if shown.
- Exact compile targets run, such as Web/H5 and Android App.
- Whether `UTS编译完毕` appeared.
- Any remaining warnings and whether they are compile-blocking.
- Focused tests run and pass counts.