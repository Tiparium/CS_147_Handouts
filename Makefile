ASSIGNMENTS := hw01 hw02 hw03 hw04 hw05 hw06 lab project
ASSIGNMENT := $(firstword $(filter-out submit,$(MAKECMDGOALS)))
DOCKER_IMAGE_NAME ?= cs147-verilog-toolchain
CONFIG_FILE := $(CURDIR)/config.json
CONFIG_SCRIPT := $(CURDIR)/student_config.py

.PHONY: submit clean_turnins clean_docker student_name help -h $(ASSIGNMENTS)

submit:
	@if [ -z "$(ASSIGNMENT)" ]; then \
		echo "Usage: make submit <assignment>"; \
		echo "Assignments: $(ASSIGNMENTS)"; \
		exit 1; \
	fi
	@if ! echo "$(ASSIGNMENTS)" | grep -qw "$(ASSIGNMENT)"; then \
		echo "Unknown assignment '$(ASSIGNMENT)'. Valid options: $(ASSIGNMENTS)"; \
		exit 1; \
	fi
	@$(MAKE) -C "assignments/$(ASSIGNMENT)" submit

help -h:
	@echo "Available make targets (run from repo root):"
	@echo "  make submit <assignment>  - run submission for hw01/hw02/hw03/hw04/hw05/hw06/lab/project"
	@echo "  make student_name         - show/update student name in config.json"
	@echo "  make clean_turnins        - delete generated submission archives (prompts)"
	@echo "  make clean_docker         - remove local Docker image (prompts; optional config cleanup)"
	@echo "  make -h / make help       - show this help"
	@if [ -z "$$RUN_HELP_SKIP_RUN" ]; then \
		RUN_HELP_SKIP_MAKE=1 ./run --help-only; \
	fi

clean_turnins:
	@echo -n "This will wipe all existing generated turn in files. Are you sure you want to continue? [y/N] " ; \
	  read ans ; \
	  case $$ans in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	  find generated_turnins -type f ! -name '.gitkeep' ! -name 'submissions.txt' -delete ; \
	  echo "Generated turn-in files removed."

clean_docker:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Error: docker not found. Run this on the host (not inside ./run)."; \
		exit 1; \
	fi
	@echo -n "Remove personal info from config.json? (recommended: no) [y/N] " ; \
	  read ans2 ; \
	  case $$ans2 in \
	    y|Y) if docker image inspect "$(DOCKER_IMAGE_NAME)" >/dev/null 2>&1; then \
	            ./run python3 student_config.py clear-student --config /repo/config.json && echo "Cleared student info."; \
	          elif command -v python3 >/dev/null 2>&1; then \
	            python3 "$(CONFIG_SCRIPT)" clear-student --config "$(CONFIG_FILE)" && echo "Cleared student info."; \
	          else \
	            echo "No image and no python3 available; skipping personal info cleanup."; \
	          fi ;; \
	    *) echo "Personal info preserved."; ;; \
	  esac
	@echo -n "This will remove the Docker image '$(DOCKER_IMAGE_NAME)'. Are you sure you want to continue? [y/N] " ; \
	  read ans ; \
	  case $$ans in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	  if docker image inspect "$(DOCKER_IMAGE_NAME)" >/dev/null 2>&1; then \
	    docker rmi -f "$(DOCKER_IMAGE_NAME)" >/dev/null && echo "Removed image $(DOCKER_IMAGE_NAME)."; \
	  else \
	    echo "Image $(DOCKER_IMAGE_NAME) not found."; \
	  fi; \
	  echo -n "Remove personal info from config.json? (recommended: no) [y/N] " ; \
	  read ans2 ; \
	  case $$ans2 in \
	    y|Y) if command -v python3 >/dev/null 2>&1; then \
	            python3 "$(CONFIG_SCRIPT)" clear-student --config "$(CONFIG_FILE)" && echo "Cleared student info."; \
	          else \
	            echo "python3 not found; skipping personal info cleanup."; \
	          fi ;; \
	    *) echo "Personal info preserved."; ;; \
	  esac

student_name:
	@./run python3 student_config.py summary --config /repo/config.json
	@echo -n "Change name? [y/N] " ; \
	  read ans ; \
	  case $$ans in \
	    y|Y) read -rp "Enter new name: " newname ; \
	         if [ -z "$$newname" ]; then echo "Name cannot be empty."; exit 1; fi ; \
	         ./run python3 student_config.py set --config /repo/config.json --name "$$newname" ; \
	         ./run python3 student_config.py summary --config /repo/config.json ;; \
	    *) echo "No changes made."; ;; \
	  esac

$(ASSIGNMENTS):
	@:
