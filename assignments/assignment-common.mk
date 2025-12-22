ASSIGNMENT_NAME ?= unknown
REPO_ROOT := $(abspath $(CURDIR)/../..)
CONFIG_FILE := $(REPO_ROOT)/config.json
ASSIGNMENTS_ROOT := $(REPO_ROOT)/assignments
TURNINS_ROOT := $(REPO_ROOT)/generated_turnins
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_DIR := $(TURNINS_ROOT)/$(ASSIGNMENT_NAME)

STUDENT_NAME ?= $(shell python3 - <<'PY'
import json, os, sys
path = os.path.normpath("$(CONFIG_FILE)")
name = None
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
        name = data.get("student", {}).get("current_name")
except FileNotFoundError:
    name = None
print(name or os.environ.get("STUDENT") or os.environ.get("USER") or "student")
PY
)

SUBMISSION_BASENAME := $(ASSIGNMENT_NAME)_$(STUDENT_NAME)_submission

.PHONY: submit
submit:
	@echo "[Assignemnt] Make Submit behavior has not yet been implemented."
	@mkdir -p "$(SUBMISSION_DIR)"
	@i=1; while [ -e "$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip" ]; do i=$$((i+1)); done; \
	  name="$(SUBMISSION_BASENAME)$${i}.zip"; \
	  echo "Creating submission archive: $${name}"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$(SUBMISSION_DIR)/$${name}" .)
