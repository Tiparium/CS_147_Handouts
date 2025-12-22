ASSIGNMENT_NAME := testing
CUSTOM_SUBMIT := 1
include ../assignment-common.mk
# Override paths after common vars are defined
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/.testing
SUBMISSION_DIR := $(TURNINS_ROOT)/.testing
ERRORS_DIR := $(ASSIGNMENT_DIR)/errors

.PHONY: submit
submit:
	@set -e; \
	  mkdir -p "$(SUBMISSION_DIR)"; \
	  ts=$$(date +"%Y%m%d-%H%M%S"); \
	  i=1; while [ -e "$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip" ]; do i=$$((i+1)); done; \
	  zip_path="$(SUBMISSION_DIR)/$(SUBMISSION_BASENAME)$${i}.zip"; \
	  tmpdir=$$(mktemp -d); \
	  echo "========================================"; \
	  echo "Creating submission archive: $$(basename "$$zip_path")"; \
	  (cd "$(ASSIGNMENT_DIR)" && zip -rq "$$zip_path" . -x "errors" "errors/*"); \
	  mkdir -p "$$tmpdir/unzipped"; \
	  unzip -q "$$zip_path" -d "$$tmpdir/unzipped"; \
	  result="pass"; \
	  force_result=""; \
	  case "$(FORCE_RESULT)" in pass|PASS|p|-p) force_result="pass" ;; fail|FAIL|f|-f) force_result="fail" ;; esac; \
	  if [ -n "$$force_result" ]; then \
	    echo "FORCED RESULT: $$force_result"; \
	    result="$$force_result"; \
	  elif ! diff -qr "$(ASSIGNMENT_DIR)" "$$tmpdir/unzipped" -x errors >/dev/null; then \
	    result="fail"; \
	  fi; \
	  pass_banner="============== PASS =============="; \
	  fail_banner="============== FAIL =============="; \
	  if [ "$$result" = "pass" ]; then \
	    echo "$$pass_banner"; \
	    echo "Archive matches working directory."; \
	    echo "$$pass_banner"; \
	    rm -rf "$$zip_path" "$$tmpdir"; \
	  else \
	    echo "$$fail_banner"; \
	    echo "Archive differs from working directory."; \
	    echo "$$fail_banner"; \
	    if [ "$$force_result" = "fail" ]; then \
	      echo "Forced fail requested; skipping error capture."; \
	      rm -rf "$$zip_path" "$$tmpdir"; \
	      exit 1; \
	    fi; \
	    err_dir="$(ERRORS_DIR)/$$ts"; \
   	    mkdir -p "$$err_dir/original"; \
	    mv "$$zip_path" "$$err_dir/"; \
	    mv "$$tmpdir/unzipped" "$$err_dir/unzipped"; \
	    find "$(ASSIGNMENT_DIR)" -mindepth 1 -maxdepth 1 ! -name errors -exec mv {} "$$err_dir/original/" \; ; \
	    printf "timestamp: %s\nresult: FAIL\nzip: %s\n" "$$ts" "$$(basename "$$zip_path")" > "$$err_dir/.meta"; \
	    rm -rf "$$tmpdir"; \
	    echo "Artifacts saved to $$err_dir"; \
	    exit 1; \
	  fi
