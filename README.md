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
This builds the `cs147-verilog-toolchain` image (or use `DOCKER_IMAGE_NAME` to override).

## Daily usage
- Run any command through the wrapper from anywhere in the repo:
  - `./run make test`
  - `./run iverilog -g2012 -o sim *.v`
  - `./run shell` for an interactive container shell
- From inside an assignment subfolder, prefix with `../run`:
  - `cd assignments/hw02`
  - `../../run make test`

The wrapper mounts the whole repo at `/repo` and mirrors your current subdirectory so relative paths work as expected. Waveforms (`.vcd`) are written to the host and can be opened with host-side viewers or VS Code extensions.

## Submitting work (scaffolding)
- Assignments live in `assignments/hw01` … `hw06`, `lab`, and `project`.
- From repo root: `./run make submit hw01` (or `hw02`, `lab`, `project`, etc.).
- Each assignment has its own `make submit` that currently emits a placeholder message and zips the assignment directory into `generated_turnins/<assignment>/`. Files are named `<assignment>_<student>_submission<N>.zip` with `N` incrementing per submission.

## Notes
- The Docker image only contains the toolchain (Icarus Verilog, make, git, bash, ca-certificates); assignments stay in your working copy.
- If you see “image not found,” run `./run setup` to (re)build locally.
