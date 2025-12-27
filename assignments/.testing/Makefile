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
	echo "[TEST] Primary Dependency: iVerilog"; \
	echo "  [INFO] TODO: add functional test here."; \
	echo "  [Result: PASS (placeholder)]"; \
	echo ""; \
	echo "[TEST] Secondary Dependencies"; \
	secondary_status=pass; \
	check_cmd() { if command -v "$$1" >/dev/null 2>&1; then echo "  [OK] $$1"; else echo "  [FAIL] $$1 missing"; secondary_status=fail; fi; }; \
	check_python_module() { \
	  if python3 -c "import importlib,sys; mod=sys.argv[1]; importlib.import_module(mod); print(f'  [OK] python module: {mod}')" "$$1"; then :; else echo "  [FAIL] python module missing: $$1"; secondary_status=fail; fi; \
	}; \
	check_cmd bash; \
	check_cmd make; \
	check_cmd git; \
	check_cmd python3; \
	check_cmd pip3; \
	check_cmd zip; \
	check_cmd unzip; \
	check_cmd tree; \
	check_cmd vim; \
	check_python_module diff_match_patch; \
	secondary_status_upper=$$(printf '%s' "$$secondary_status" | tr '[:lower:]' '[:upper:]'); \
	echo "  [Result: $$secondary_status_upper]"; \
	echo ""; \
	echo "[TEST] Compression / Decompression"; \
	echo "Creating submission archive: $$(basename "$$zip_path")"; \
	(cd "$(ASSIGNMENT_DIR)" && zip -rq "$$zip_path" . -x "errors" "errors/*"); \
	mkdir -p "$$tmpdir/unzipped"; \
	unzip -q "$$zip_path" -d "$$tmpdir/unzipped"; \
	result="pass"; \
	force_result=""; \
	case "$(FORCE_RESULT)" in pass|PASS|p|-p) force_result="pass" ;; fail|FAIL|f|-f) force_result="fail" ;; esac; \
	if [ -n "$$force_result" ]; then \
	  echo "  FORCED RESULT: $$force_result"; \
	  result="$$force_result"; \
	elif ! diff -qr "$(ASSIGNMENT_DIR)" "$$tmpdir/unzipped" -x errors >/dev/null; then \
	  result="fail"; \
	fi; \
	if [ "$$result" = "pass" ]; then \
	  echo "  [Result: PASS]"; \
	  echo ""; \
	  rm -rf "$$zip_path" "$$tmpdir"; \
	else \
	  echo "  [Result: FAIL]"; \
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
	  echo ""; \
	  exit 1; \
	fi; \
	if [ "$$secondary_status" != "pass" ]; then exit 1; fi
