ASSIGNMENT_NAME ?= unknown
REPO_ROOT := $(abspath $(CURDIR)/../..)
PROFILE_FILE := $(REPO_ROOT)/student_profile.env
ASSIGNMENTS_ROOT := $(REPO_ROOT)/assignments
TURNINS_ROOT := $(REPO_ROOT)/generated_turnins
ASSIGNMENT_DIR ?= $(ASSIGNMENTS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_DIR ?= $(TURNINS_ROOT)/$(ASSIGNMENT_NAME)

STUDENT_NAME_FROM_PROFILE := $(shell if [ -f "$(PROFILE_FILE)" ]; then bash -lc 'source "$(PROFILE_FILE)" >/dev/null 2>&1 || true; printf "%s" "$${STUDENT_NAME:-}"'; fi)

ifeq ($(strip $(STUDENT_NAME_FROM_PROFILE)),)
  ifeq ($(strip $(STUDENT)),)
    $(info Student name is not set.)
    $(info Run ./run setup (builds the image and records your student profile) or ./run make student_name.)
    $(error If Docker is unavailable, contact the instructor.)
  else
    STUDENT_NAME := $(STUDENT)
  endif
else
  STUDENT_NAME := $(STUDENT_NAME_FROM_PROFILE)
endif

SUBMISSION_BASENAME := $(ASSIGNMENT_NAME)_$(STUDENT_NAME)_submission
LAST_ZIP_MARKER := $(ASSIGNMENT_DIR)/.last_submit_zip

.PHONY: submit
ifndef CUSTOM_SUBMIT
submit:
	@set +e; test_rc=0; \
	(cd "$(ASSIGNMENTS_ROOT)" && bash -lc 'set -o pipefail; ./.testing/test_runner.sh $(ASSIGNMENT_NAME) | tee "$(ASSIGNMENT_DIR)/submission_report.log"'); \
	test_rc=$$?; set -e; \
	if [ "$$test_rc" -ne 0 ]; then \
	  echo "[submit] NOTE: Tests reported failures (rc=$$test_rc). See $(ASSIGNMENT_NAME)/submission_report.log for details."; \
	fi
	@# Capture verbose test output separately for debugging (not shown to user)
	@set +e; (cd "$(ASSIGNMENTS_ROOT)" && bash -lc 'set -o pipefail; ./.testing/test_runner.sh -v $(ASSIGNMENT_NAME) > "$(ASSIGNMENT_DIR)/submission_report_verbose.log"'); set -e
	@echo "[submit] computing hashes..."
	@report_body="$(ASSIGNMENT_DIR)/submission_report.body.log"; \
	cp "$(ASSIGNMENT_DIR)/submission_report.log" "$$report_body"; \
	(cd "$(ASSIGNMENT_DIR)" && \
	  if [ "$(ASSIGNMENT_NAME)" = "hw04" ]; then \
	    files="$$(find . \( -type f -o -type l \) \( -name '*.v' -o -name '*.sv' -o -name '*.asm' -o -name '*.txt' \) ! -name 'submission_report.log' ! -name 'submission_report_verbose.log' -print)"; \
	  else \
	    files="$$(find . \( -type f -o -type l \) \( -name '*.v' -o -name '*.sv' \) ! -name 'submission_report.log' ! -name 'submission_report_verbose.log' -print)"; \
	  fi; \
	  if [ -n "$$files" ]; then \
	    printf "%s\n" "$$files" | LC_ALL=C sort | xargs sha256sum; \
	  fi; \
	  report_hash="$$(sha256sum "$$report_body" | awk '{print $$1}')"; \
	  echo "$$report_hash  submission_report.log"; \
	) >"$(ASSIGNMENT_DIR)/hashes.tmp"; \
	rm -f "$$report_body"
	@if [ "${AG_HASH_VERBOSE}" = "1" ]; then \
	  echo "================ HASH REPORT (pre-zip) ================"; \
	  cat "$(ASSIGNMENT_DIR)/hashes.tmp"; \
	  echo "======================================================="; \
	fi
	@cat "$(ASSIGNMENT_DIR)/hashes.tmp" "$(ASSIGNMENT_DIR)/submission_report.log" >"$(ASSIGNMENT_DIR)/submission_report.log.tmp"
	@mv "$(ASSIGNMENT_DIR)/submission_report.log.tmp" "$(ASSIGNMENT_DIR)/submission_report.log"
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
	@rm -f "$(ASSIGNMENT_DIR)/submission_report.log" "$(ASSIGNMENT_DIR)/submission_report_verbose.log"
endif
