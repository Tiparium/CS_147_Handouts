ASSIGNMENT_NAME ?= unknown
STUDENT_NAME ?= $(or $(STUDENT),$(USER),student)

REPO_ROOT := $(abspath $(CURDIR)/../..)
ASSIGNMENTS_ROOT := $(REPO_ROOT)/assignments
TURNINS_ROOT := $(REPO_ROOT)/generated_turnins
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_DIR := $(TURNINS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_BASENAME := $(ASSIGNMENT_NAME)_$(STUDENT_NAME)_submission

.PHONY: submit
submit:
	@echo "[Assignemnt] Make Submit behavior has not yet been implemented."
	@mkdir -p "$(SUBMISSION_DIR)"
	@i=1; while [ -e "$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip" ]; do i=$$((i+1)); done; \
	  name="$(SUBMISSION_BASENAME)$${i}.zip"; \
	  echo "Creating submission archive: $${name}"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$(SUBMISSION_DIR)/$${name}" .)
