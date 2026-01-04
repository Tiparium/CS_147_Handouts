ASSIGNMENT_NAME ?= unknown
REPO_ROOT := $(abspath $(CURDIR)/../..)
CONFIG_FILE := $(REPO_ROOT)/config.json
CONFIG_SCRIPT := $(REPO_ROOT)/student_config.py
ASSIGNMENTS_ROOT := $(REPO_ROOT)/assignments
TURNINS_ROOT := $(REPO_ROOT)/generated_turnins
ASSIGNMENT_DIR ?= $(ASSIGNMENTS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_DIR ?= $(TURNINS_ROOT)/$(ASSIGNMENT_NAME)

STUDENT_NAME_FROM_CONFIG := $(shell if command -v python3 >/dev/null 2>&1; then python3 "$(CONFIG_SCRIPT)" --config "$(CONFIG_FILE)" current 2>/dev/null; fi)

ifeq ($(strip $(STUDENT_NAME_FROM_CONFIG)),)
  ifeq ($(strip $(STUDENT)),)
    $(info Student name is not set.)
    $(info Run ./run setup (builds the image and records your name) or ./run make student_name.)
    $(error If Docker is unavailable, contact the instructor.)
  else
    STUDENT_NAME := $(STUDENT)
  endif
else
  STUDENT_NAME := $(STUDENT_NAME_FROM_CONFIG)
endif

SUBMISSION_BASENAME := $(ASSIGNMENT_NAME)_$(STUDENT_NAME)_submission
LAST_ZIP_MARKER := $(ASSIGNMENT_DIR)/.last_submit_zip

.PHONY: submit
ifndef CUSTOM_SUBMIT
submit:
	@echo "[submit] running tests for $(ASSIGNMENT_NAME)..."
	@echo "[submit] running tests for $(ASSIGNMENT_NAME)..."
	@set +e; test_rc=0; \
	(cd "$(ASSIGNMENTS_ROOT)" && bash -lc 'set -o pipefail; ./.testing/test_runner.sh $(ASSIGNMENT_NAME) | tee "$(ASSIGNMENT_DIR)/submission_report.txt"'); \
	test_rc=$$?; set -e; \
	if [ "$$test_rc" -ne 0 ]; then \
	  echo "[submit] NOTE: Tests reported failures (rc=$$test_rc). See $(ASSIGNMENT_NAME)/submission_report.txt for details."; \
	fi
	@# Capture verbose test output separately for debugging (not shown to user)
	@set +e; (cd "$(ASSIGNMENTS_ROOT)" && bash -lc 'set -o pipefail; ./.testing/test_runner.sh -v $(ASSIGNMENT_NAME) > "$(ASSIGNMENT_DIR)/submission_report_verbose.txt"'); set -e
	@echo "[submit] computing hashes..."
	@(cd "$(ASSIGNMENT_DIR)" && find . -type f \( -name '*.v' -o -name '*.sv' \) | LC_ALL=C sort | sha256sum) >"$(ASSIGNMENT_DIR)/hashes.tmp"
	@cat "$(ASSIGNMENT_DIR)/hashes.tmp" "$(ASSIGNMENT_DIR)/submission_report.txt" >"$(ASSIGNMENT_DIR)/submission_report.txt.tmp"
	@mv "$(ASSIGNMENT_DIR)/submission_report.txt.tmp" "$(ASSIGNMENT_DIR)/submission_report.txt"
	@rm -f "$(ASSIGNMENT_DIR)/hashes.tmp"
	@zip_path="" ; name="" ; marker="$(LAST_ZIP_MARKER)"; \
	if [ "${JUSTGRADE}" = "1" ]; then \
	  zip_path="$(ASSIGNMENT_DIR)/grade_tmp_submission.zip"; \
	  name="$${zip_path##*/}"; \
	  echo "[submit] creating temp grader archive: $${name}"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$${zip_path}" .); \
	else \
	  mkdir -p "$(SUBMISSION_DIR)"; \
	  i=1; while [ -e "$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip" ]; do i=$$((i+1)); done; \
	  name="$(SUBMISSION_BASENAME)$${i}.zip"; \
	  zip_path="$(SUBMISSION_DIR)/$${name}"; \
	  echo "[submit] creating submission archive: $${name}"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$${zip_path}" .); \
	fi; \
	if [ -d "$(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/test_submissions" ]; then \
	  cp "$${zip_path}" "$(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/test_submissions/$${name}"; \
	  echo "$(ASSIGNMENT_NAME) Gradescope_Autograder_Template/test_submissions/$${name}" > "$${marker}"; \
	  echo "[submit] grader copy ready at Gradescope_Autograder_Template/test_submissions/$${name}"; \
	else \
	  echo "[submit] Gradescope_Autograder_Template/test_submissions not found; skipping grader copy."; \
	fi; \
	if [ "${JUSTGRADE}" = "1" ]; then rm -f "$${zip_path}"; fi
	@rm -f "$(ASSIGNMENT_DIR)/submission_report.txt"
endif
