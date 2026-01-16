PUBLIC_ASSIGNMENTS := hw01 hw02 hw03 hw04 hw05 hw06 lab project
ASSIGNMENTS := $(PUBLIC_ASSIGNMENTS) .testing
ASSIGNMENT := $(firstword $(filter-out submit,$(MAKECMDGOALS)))
DOCKER_IMAGE_NAME ?= cs147-verilog-toolchain
AUTOGRADER_IMAGE_NAME ?= gradescope/autograder-base
CONFIG_FILE := $(CURDIR)/config.json
CONFIG_SCRIPT := $(CURDIR)/student_config.py

.PHONY: submit clean_turnins clean_docker nuke_docker clean student_name help -h wave_test $(ASSIGNMENTS)

submit:
	@if [ -z "$(ASSIGNMENT)" ]; then \
		echo "Usage: make submit <assignment>"; \
		echo "Assignments: $(PUBLIC_ASSIGNMENTS)"; \
		exit 1; \
	fi
	@if ! echo "$(ASSIGNMENTS)" | grep -qw "$(ASSIGNMENT)"; then \
		echo "Unknown assignment '$(ASSIGNMENT)'. Valid options: $(PUBLIC_ASSIGNMENTS)"; \
		exit 1; \
	fi
	@$(MAKE) -C "assignments/$(ASSIGNMENT)" submit

help -h:
	@echo "Available make targets (run from repo root):"
	@echo "  make submit <assignment>  - run submission for $(PUBLIC_ASSIGNMENTS)"
	@echo "  make student_name         - show/update student name in config.json"
	@echo "  make wave_test            - generate VCD waveforms for .testing mux examples"
	@echo "  make clean_turnins        - delete generated submission archives (prompts)"
	@echo "  make clean_docker         - remove local Docker images (toolchain + autograder base) (prompts; optional config cleanup)"
	@echo "  make nuke_docker          - forcibly remove only the toolchain/autograder images (cache) (prompts)"
	@echo "  make clean                - run all clean_* targets and remove local self-test logs"
	@echo "  make -h / make help       - show this help"
	@if [ -z "$$RUN_HELP_SKIP_RUN" ]; then \
		RUN_HELP_SKIP_MAKE=1 ./run --help-only; \
	fi

wave_test:
	@./run make -C assignments/.testing waves

clean_turnins:
	@echo -n "This will wipe all existing generated turn in files. Are you sure you want to continue? [y/N] " ; \
	  read ans ; \
	  case $$ans in y|Y) \
	    find generated_turnins -type f ! -name '.gitkeep' ! -name 'submissions.txt' -delete ; \
	    echo "Generated turn-in files removed." ;; \
	    *) echo "Skipped cleaning turn-ins."; ;; \
	  esac

clean_docker:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Error: docker not found. Run this on the host (not inside ./run)."; \
		exit 1; \
	fi
	@target_ids=$$(docker images --format '{{.Repository}} {{.ID}}' | awk -v t="$(DOCKER_IMAGE_NAME)" -v a="$(AUTOGRADER_IMAGE_NAME)" '$$1==t || $$1==a {print $$2}'); \
	echo -n "This will remove Docker images '$(DOCKER_IMAGE_NAME)' and '$(AUTOGRADER_IMAGE_NAME)'. Are you sure you want to continue? [y/N] " ; \
	  read ans ; \
	  case $$ans in y|Y) \
	    for img in "$(DOCKER_IMAGE_NAME)" "$(AUTOGRADER_IMAGE_NAME)"; do \
	      if docker image inspect "$$img" >/dev/null 2>&1; then \
	        docker rmi -f "$$img" >/dev/null && echo "Removed image $$img."; \
	      else \
	        echo "Image $$img not found."; \
	      fi; \
	    done; \
	    dangling_from_targets=$$(docker images --format '{{.ID}} {{.Repository}} {{.Tag}}' | awk -v ids="$$target_ids" 'BEGIN{n=split(ids,a,/[^0-9a-f]+/); for(i=1;i<=n;i++) if(a[i]!="") s[a[i]]=1} $$2=="<none>" && s[$$1]{print $$1}'); \
	    if [ -n "$$dangling_from_targets" ]; then \
	      echo "$$dangling_from_targets" | xargs -r docker rmi -f >/dev/null && echo "Removed dangling images for $(DOCKER_IMAGE_NAME)/$(AUTOGRADER_IMAGE_NAME)."; \
	    fi; \
	    echo -n "Remove personal info from config.json? (recommended: no) [y/N] " ; \
	    read ans2 ; \
	    case $$ans2 in \
	      y|Y) if command -v python3 >/dev/null 2>&1; then \
	              python3 "$(CONFIG_SCRIPT)" --config "$(CONFIG_FILE)" clear-student && echo "Cleared student info."; \
	            else \
	              echo "python3 not found; skipping personal info cleanup."; \
	            fi ;; \
	      *) echo "Personal info preserved."; ;; \
	    esac ;; \
	    *) echo "Skipped cleaning Docker images."; ;; \
	  esac

nuke_docker:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Error: docker not found. Run this on the host (not inside ./run)."; \
		exit 1; \
	fi
	@if [ -f /.dockerenv ]; then \
		echo "Error: Do NOT run nuke_docker inside the course container. Run from the host shell."; \
		exit 1; \
	fi
	@echo "================ BIG RED BUTTON ================"; \
	echo "You are about to forcibly stop/remove containers and images for:"; \
	echo "  - $(DOCKER_IMAGE_NAME)"; \
	echo "  - $(AUTOGRADER_IMAGE_NAME)"; \
	echo "Other images will NOT be touched."; \
	echo "================================================"; \
	echo "If containers are running from these images, they must be stopped first."
	@running_ids=$$(docker ps -q --filter "ancestor=$(DOCKER_IMAGE_NAME)" --filter "ancestor=$(AUTOGRADER_IMAGE_NAME)"); \
	if [ -n "$$running_ids" ]; then \
	  echo "WARNING: Found running containers that use these images:"; \
	  docker ps --filter "ancestor=$(DOCKER_IMAGE_NAME)" --filter "ancestor=$(AUTOGRADER_IMAGE_NAME)"; \
	  echo -n "Are you sure? Stop and remove these containers to continue? [y/N] " ; \
	  read ansr ; \
	  case $$ansr in y|Y) docker stop $$running_ids >/dev/null && docker rm $$running_ids >/dev/null ;; *) echo "Aborted."; exit 1;; esac; \
	fi
	@stopped_ids=$$(docker ps -aq --filter "ancestor=$(DOCKER_IMAGE_NAME)" --filter "ancestor=$(AUTOGRADER_IMAGE_NAME)"); \
	if [ -n "$$stopped_ids" ]; then \
	  echo "NOTE: Found stopped containers using these images; they will be removed."; \
	  docker rm $$stopped_ids >/dev/null; \
	fi
	@target_ids=$$(docker images --filter=reference="$(DOCKER_IMAGE_NAME)" --filter=reference="$(DOCKER_IMAGE_NAME):latest" --filter=reference="$(AUTOGRADER_IMAGE_NAME)" --filter=reference="$(AUTOGRADER_IMAGE_NAME):latest" -q | sort -u); \
	echo -n "Proceed to remove images (and remaining tags) for these IDs? [y/N] " ; \
	read ans ; \
	case $$ans in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	if [ -n "$$target_ids" ]; then \
	  echo "Removing images..."; \
	  echo "$$target_ids" | xargs -r docker rmi -f >/dev/null || true; \
	else \
	  echo "No tagged images found for $(DOCKER_IMAGE_NAME) or $(AUTOGRADER_IMAGE_NAME)."; \
	fi; \
	dang=$$(docker images --filter dangling=true -q); \
	if [ -n "$$dang" ]; then \
	  echo -n "Optional: remove dangling <none> images too? [y/N] " ; \
	  read ansd ; \
	  case $$ansd in y|Y) echo "$$dang" | xargs -r docker rmi -f >/dev/null ;; *) ;; esac; \
	fi; \
	echo "Done. Note: other Docker images were not touched."

clean_logs:
	@rm -f .testing_selftest_attempt*.log
	@rm -f assignments/.testing/selftest_logs/.testing_selftest_attempt*.log
	@find assignments -type f \( -name '*.vcd' -o -name '*.log' -o -name '*.out' \) -delete
	@echo "Removed logs, VCDs, and bench outputs under assignments/."

CLEAN_STEPS := clean_turnins clean_docker clean_logs

clean:
	@cleaned=""; skipped=""; \
	for tgt in $(CLEAN_STEPS); do \
		case "$$tgt" in \
		  clean_turnins) \
		    echo -n "Clean turn-ins? [y/N] " ; read ans ; \
		    case $$ans in \
		      y|Y) find generated_turnins -type f ! -name '.gitkeep' ! -name 'submissions.txt' -delete ; \
		           echo "Turn-ins cleaned."; cleaned="$$cleaned $$tgt" ;; \
		      *) echo "Turn-ins skipped."; skipped="$$skipped $$tgt" ;; \
		    esac ;; \
		  clean_docker) \
		    if ! command -v docker >/dev/null 2>&1; then \
		      echo "Docker not found; skipping Docker clean."; skipped="$$skipped $$tgt" ; \
		    else \
		      target_ids=$$(docker images --format '{{.Repository}} {{.ID}}' | awk -v t="$(DOCKER_IMAGE_NAME)" -v a="$(AUTOGRADER_IMAGE_NAME)" '$$1==t || $$1==a {print $$2}'); \
		      echo -n "Clean Docker images ($(DOCKER_IMAGE_NAME), $(AUTOGRADER_IMAGE_NAME))? [y/N] " ; read ans ; \
		      case $$ans in \
		        y|Y) for img in "$(DOCKER_IMAGE_NAME)" "$(AUTOGRADER_IMAGE_NAME)"; do \
			          if docker image inspect "$$img" >/dev/null 2>&1; then \
			            docker rmi -f "$$img" >/dev/null && echo "Removed image $$img."; \
			          else \
			            echo "Image $$img not found."; \
			          fi; \
			        done; \
			        dangling_from_targets=$$(docker images --format '{{.ID}} {{.Repository}} {{.Tag}}' | awk -v ids="$$target_ids" 'BEGIN{n=split(ids,a,/[^0-9a-f]+/); for(i=1;i<=n;i++) if(a[i]!="") s[a[i]]=1} $$2=="<none>" && s[$$1]{print $$1}'); \
			        if [ -n "$$dangling_from_targets" ]; then \
			          echo "$$dangling_from_targets" | xargs -r docker rmi -f >/dev/null && echo "Removed dangling images for $(DOCKER_IMAGE_NAME)/$(AUTOGRADER_IMAGE_NAME)."; \
			        fi; \
			        echo -n "Remove personal info from config.json? (recommended: no) [y/N] " ; read ans2 ; \
			        case $$ans2 in \
			          y|Y) if command -v python3 >/dev/null 2>&1; then \
			                  python3 "$(CONFIG_SCRIPT)" --config "$(CONFIG_FILE)" clear-student && echo "Cleared student info."; \
			                else \
			                  echo "python3 not found; skipping personal info cleanup."; \
			                fi ;; \
			          *) echo "Personal info preserved."; ;; \
			        esac; \
			        cleaned="$$cleaned $$tgt" ;; \
		        *) echo "Docker clean skipped."; skipped="$$skipped $$tgt" ;; \
		      esac; \
		    fi ;; \
		  clean_logs) \
		    echo -n "Clean log files? [y/N] " ; read ans ; \
		    case $$ans in \
		      y|Y) rm -f .testing_selftest_attempt*.log assignments/.testing/selftest_logs/.testing_selftest_attempt*.log; \
		           find assignments -type f \( -name '*.vcd' -o -name '*.log' -o -name '*.out' \) -delete; \
		           echo "Logs cleaned."; cleaned="$$cleaned $$tgt" ;; \
		      *) echo "Logs skipped."; skipped="$$skipped $$tgt" ;; \
		    esac ;; \
		esac; \
	done; \
	echo "Clean summary:"; \
	echo "  cleaned: $$cleaned"; \
	echo "  skipped: $$skipped"

student_name:
	@./run python3 student_config.py --config /repo/config.json summary
	@echo -n "Change name? [y/N] " ; \
	  read ans ; \
	  case $$ans in \
	    y|Y) read -rp "Enter new name: " newname ; \
	         if [ -z "$$newname" ]; then echo "Name cannot be empty."; exit 1; fi ; \
	         ./run python3 student_config.py --config /repo/config.json set --name "$$newname" ; \
	         ./run python3 student_config.py --config /repo/config.json summary ;; \
	    *) echo "No changes made."; ;; \
	  esac

$(ASSIGNMENTS):
	@:
