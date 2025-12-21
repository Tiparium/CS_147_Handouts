ASSIGNMENTS := hw01 hw02 hw03 hw04 hw05 hw06 lab project
ASSIGNMENT := $(firstword $(filter-out submit,$(MAKECMDGOALS)))

.PHONY: submit clean_turnins $(ASSIGNMENTS)

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

clean_turnins:
	@echo -n "This will wipe all existing generated turn in files. Are you sure you want to continue? [y/N] " ; \
	  read ans ; \
	  case $$ans in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	  find generated_turnins -type f ! -name '.gitkeep' ! -name 'submissions.txt' -delete ; \
	  echo "Generated turn-in files removed."

$(ASSIGNMENTS):
	@:
