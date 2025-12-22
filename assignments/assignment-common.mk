ASSIGNMENT_NAME ?= unknown
REPO_ROOT := $(abspath $(CURDIR)/../..)
CONFIG_FILE := $(REPO_ROOT)/config.json
CONFIG_SCRIPT := $(REPO_ROOT)/student_config.py
ASSIGNMENTS_ROOT := $(REPO_ROOT)/assignments
TURNINS_ROOT := $(REPO_ROOT)/generated_turnins
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/$(ASSIGNMENT_NAME)
SUBMISSION_DIR := $(TURNINS_ROOT)/$(ASSIGNMENT_NAME)

STUDENT_NAME_FROM_CONFIG := $(shell if command -v python3 >/dev/null 2>&1; then python3 "$(CONFIG_SCRIPT)" current --config "$(CONFIG_FILE)" 2>/dev/null; fi)

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

.PHONY: submit
submit:
	@echo "[Assignemnt] Make Submit behavior has not yet been implemented."
	@mkdir -p "$(SUBMISSION_DIR)"
	@i=1; while [ -e "$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip" ]; do i=$$((i+1)); done; \
	  name="$(SUBMISSION_BASENAME)$${i}.zip"; \
	  echo "Creating submission archive: $${name}"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$(SUBMISSION_DIR)/$${name}" .)
