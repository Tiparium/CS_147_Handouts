# CS 147 Docker-Based Verilog Workflow

This repo holds CS 147 handouts and homework. Tooling runs inside Docker so students get a consistent Verilog environment on macOS, Windows, and Linux without installing Icarus locally.

## Prerequisites
- Install Docker Desktop (or Docker Engine on Linux).
- Clone this repository: `git clone https://github.com/Tiparium/CS_147_Handouts.git`

## One-time setup
```bash
cd CS_147_Handouts
./run setup
```
You’ll be prompted for your name (used in submission zips). This builds the `cs147-verilog-toolchain` image (or use `DOCKER_IMAGE_NAME` to override).

## Daily usage
- Run any command through the wrapper from anywhere in the repo:
  - `./run make test`
  - `./run iverilog -g2012 -o sim *.v`
  - `./run shell` for an interactive container shell
  - `./run test hw01 [hw1_2]` to run assignment benches (quiet summary by default; add `-v` for full logs)
  - `./run verilog_checker <assignment|path>` to run the Java Vcheck tool on assignments or specific files
- From inside an assignment subfolder, prefix with `../run`:
  - `cd assignments/hw02`
  - `../../run make test`

The wrapper mounts the whole repo at `/repo` and mirrors your current subdirectory so relative paths work as expected. Waveforms (`.vcd`) are written to the host and can be opened with host-side viewers or VS Code extensions.

## Submitting work (scaffolding)
- Assignments live in `assignments/hw01` … `hw06`, `lab`, and `project`.
- From repo root: `./run submit hw01` (or `hw02`, `lab`, `project`, etc.).
- Each assignment has its own submit flow that currently emits a placeholder message and zips the assignment directory into `generated_turnins/<assignment>/`. Files are named `<assignment>_<student>_submission<N>.zip` with `N` incrementing per submission.
- Submit requires your name in `config.json`. If it’s missing, you’ll be asked to run `./run setup` (builds image and records your name) or `./run student_name` to set it.

## Common commands (root)
- `./run setup` — build/pull the toolchain image, prompt for student name, run self-test
- `./run shell` — interactive shell inside the container at your current repo subdir
- `./run <cmd>` — run any command inside the container (e.g., `make test`, `iverilog …`)
- `./run test <hw> [sub]` — run testbenches for an assignment (quiet PASS/FAIL summary; add `-v` for full logs)
- `./run verilog_checker <assignment|path>` — run Vcheck on an assignment (recursive) or a specific `.v` file / non-recursive directory
- `./run submit <assignment>` — run the assignment’s submit flow
- `./run wave_test` — generate VCD waveforms for the .testing mux examples
- `./run student_name` — view/update your recorded student name
- `./run clean_turnins` — delete generated submission archives (prompts)
- `./run clean_docker` — remove local Docker images (toolchain + autograder base) with confirmation; optional config cleanup
- `./run clean` — run all clean_* targets and remove local self-test logs
- Host-only: `make nuke_docker` — forcibly remove the toolchain and autograder images (cache) with confirmations; do not run via `./run`

## Notes
- Your name is stored in `config.json` in the repo root (ignored by git). Use `make student_name` to view/change it; previous names are retained.
- To rebuild from scratch on your machine: run `make clean_docker` (on the host, not via `./run`) to remove the local image; it can optionally clear your name from `config.json`.
- The Docker image only contains the toolchain (Icarus Verilog, make, git, bash, ca-certificates); assignments stay in your working copy.
- If you see “image not found,” run `./run setup` to (re)build locally.
