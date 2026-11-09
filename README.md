# Unfair Bossfight

One Roblox experience made of several places, grouped in this repo.

```
boss/     The Golden Encounter (alterGolden's Bossfight). Rojo project: boss/default.project.json
lobby/    Unfair Bossfight lobby: class picker, party pads, teleporters. Rojo project: lobby/default.project.json
shared/   Code mounted into both places (UnfairShared: config, teleport payload, cash rules)
docs/     intent/ (what we want) and spec/ (how it should work)
tasks/    unfair-bossfight/ plan.md and todo.md (boss/tasks holds the earlier code-cleanup record)
```

Open `UnfairBossfight.code-workspace` in VS Code to get all four folders with the right Luau settings.

## Rojo ports

| Project | Command | Port |
|---|---|---|
| boss | `rojo serve boss/default.project.json --port 34872` | 34872 |
| lobby | `rojo serve lobby/default.project.json --port 34873` | 34873 |

Connect each Studio instance to its own port. If Studio stops receiving changes, check that the matching `rojo` process is still running.

## Checks

`powershell -ExecutionPolicy Bypass -File boss/tools/check.ps1` builds the boss project, runs the Luau analyzer
against its baseline and checks the mirror pairs. See [boss/README.md](boss/README.md) for how the boss place's
files are laid out and exported.

Plan: [tasks/unfair-bossfight/plan.md](tasks/unfair-bossfight/plan.md). Spec: [docs/spec/unfair-bossfight.md](docs/spec/unfair-bossfight.md).
