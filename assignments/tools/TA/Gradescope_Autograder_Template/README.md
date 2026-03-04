# Autograder Template

Reusable scaffold for Gradescope-style autograders, plus a local Docker harness that mirrors `gradescope/autograder-base`.

## Layout
- `run_autograder` — entrypoint called in the container; copies grader/traces into the submission, runs grading, emits `results.json`.
- `grade.py` — template grader logic; customize `run_assignment_tests` and `apply_curve`.
- `gen_output.py` — parses grader output and writes Gradescope `results.json`.
- `setup.sh` — runtime dependency installer (runs inside container during grading).
- `traces/` — place assignment-specific trace/input files here.
- `drafts/` — where packaged zips land (ignored by git; contains `.gitkeep`).
- `test_submissions/` — local submissions for testing (ignored by git; contains `.gitkeep`).
- `docker/` — Dockerfile for the local test image.
- `run` — helper script to build the image and grade locally.
- `Makefile` — helper targets for naming and packaging.

## Quickstart
1) Set a lab name (stored in `labname.cfg`):
   ```bash
   make name LAB=my_lab
   ```
2) Build the local image (mirrors Gradescope base):
   ```bash
   ./run setup
   ```
3) Add a test submission under `test_submissions/<case>/`.
4) Run the grader locally (directory or zip path):
   ```bash
   ./run grade test_submissions/<case>
   # or
   ./run grade test_submissions/<case>.zip
   # results in local_results/
   ```

## Makefile helpers
- `make name LAB=<lab>` — set lab name into `labname.cfg`.
- `make submit` — zip the autograder (excluding `docker/`, `drafts/`, `test_submissions/`) to `drafts/<lab>_draft_XX.zip`. Lab comes from `LAB`/`NAME` or `labname.cfg`.

## Packaging for Gradescope
Use `make submit` after setting the lab name. Upload the produced zip from `drafts/`.

## Local Docker Grading
- `./run setup` — build image from `docker/Dockerfile` (tag `autograder-local`).
- `./run grade <submission_dir>` — mount repo to `/autograder/source`, the submission to `/autograder/submission`, and write outputs to `local_results/`. If `<submission_dir>` is omitted, uses the first folder under `test_submissions/`.
- Uses the same `run_autograder` + `setup.sh` flow as Gradescope; dependencies are installed at runtime inside the container.

## Config knobs
- Assignment naming: `make name` writes `labname.cfg` and `run_autograder` uses it as default `ASSIGNMENT_NAME` (env overrides still apply).
- Grader scaling/clamping: adjust `CONFIG` in `grade.py` or override via env `TOTAL_POINTS`.
- Parser defaults: adjust `CONFIG` in `gen_output.py` or pass CLI flags (`--assignment-name`, `--total-points`).

## Git hygiene
- `.gitignore` keeps contents of `drafts/` and `test_submissions/` out of version control while retaining directories via `.gitkeep`.
