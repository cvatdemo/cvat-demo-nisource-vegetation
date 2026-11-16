# NiSource demo on open-source CVAT

This folder lets you run the demo you saw on your own machine, with open-source CVAT v2.82.0.
It contains the demo project (100 photos, the labels, a model's first-pass polygons and a
20-photo answer key), scripts to start CVAT and load the project, and a click-through of
the full demo as it looked in CVAT Online.

**The use case:** NiSource owns and operates natural gas (Columbia Gas) and electric (NIPSCO) infrastructure. It collects or buys aerial imagery of its own pipeline rights-of-way and power line corridors and wants trustworthy vegetation labels to prioritize its clearing crews and contractors and to stay compliant. The baseline question on each aerial tile is simply: is there vegetation here or not. Gas and electric are two business lines inside the same utility with different clearance drivers; here they are talk-track framing, not label classes.

**The photos** are a public dataset, not your data: Aerial imagery from OpenAerialMap contributors, tree-crown annotations from the Restor Foundation OAM-TCD dataset (restor/tcd on Hugging Face). Licensed CC BY 4.0. Only CC-BY-4.0-licensed tiles are used.. Details in `LICENSES.md`.

## What you need

- Docker Desktop (running), with about 8 GB of memory available to it
- git, and Python 3.10 or newer (or `uv`, which downloads one for you)
- About 10 GB of free disk space and a few minutes for the first start

## Start

Open `START-HERE.html` in a browser for the short version. Or, in a terminal in this folder:

```bash
bash start.sh
```

That one command starts CVAT at http://localhost:8080, loads the demo project and its quality
rules, prints the scores, and opens your browser. It prints the sign-in at the end: user `demo`,
with a password created on your machine and saved in `.demo-credentials`.

Then follow `WALKTHROUGH.md`. Open `clickthrough.html` to see every screen from the demo,
including the CVAT Online features that open source does not have.

The same thing step by step: `bash scripts/setup.sh`, `bash scripts/restore.sh`,
`bash scripts/quality_report.sh`.

Optional: `bash scripts/auto_annotate.sh` runs the same hosted Roboflow model on your machine (through the Roboflow API with your own key) and uploads its vegetation polygons, the same way your own model would plug in. It runs on the empty run task and leaves the answer key alone. The model's first pass is already in the backup, so this is optional.

When you are done: `bash scripts/stop.sh` (keeps your data) or `bash scripts/stop.sh --delete`.

## Windows

Run it inside WSL 2 (Ubuntu). In Docker Desktop, turn on Settings > Resources > WSL integration
for your distribution. Unzip the folder inside your WSL home folder (for example `~/cvat-demo`),
not on the C: drive, and run the commands in the Ubuntu terminal. If Python reports that venv is
missing, run `sudo apt install python3-venv`. Open http://localhost:8080 in your Windows browser.

## What is free and what is CVAT Online

| Works here (open source) | CVAT Online or Enterprise only |
|---|---|
| Projects, labels, attributes, tags | "Finish the job" check that bounces an incomplete batch |
| Import and export in standard formats | The quality control screens (scores and rules in the browser) |
| Cloud storage connections | Segment Anything 3 text prompts |
| Answer key (ground truth) jobs, and quality scores through `scripts/quality_report.sh` | Outsource Labeling to CVAT annotators |
| Running your own model through `cvat-cli` | Roboflow and Hugging Face model integration |
| Manual annotation and review | One-click automatic annotation with built-in models (open source needs a separate Nuclio setup) |

## What is in the folder

```
START-HERE.html    open this first
start.sh           one command to start everything
README.md          this file
CLAUDE.md          instructions for an AI coding assistant to set this up for you
WALKTHROUGH.md     the demo as a self-guided tour, each step marked free or CVAT Online
clickthrough.html  the full demo as a click-through (opens from disk, no network)
demo/backup.zip    the project: photos, labels, model first pass, answer key
demo/quality.json  the quality rules
model/             the Roboflow function file for scripts/auto_annotate.sh (no weights; uses your own key)
scripts/           setup, restore, quality report, auto-annotate, stop
docker/            where CVAT v2.82.0 is cloned
LICENSES.md        credit for the photos, the model and CVAT
```

## If something goes wrong

- **"Docker is installed but not running":** start Docker Desktop, wait for it to finish starting, run it again. In WSL, also turn on WSL integration (see Windows above).
- **CVAT does not come up:** `docker logs cvat_server` shows why. Port 8080 must be free.
- **Start over:** `bash scripts/stop.sh --delete`, then `bash start.sh`.
