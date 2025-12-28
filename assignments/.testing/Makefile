ASSIGNMENT_NAME := testing
CUSTOM_SUBMIT := 1
include ../assignment-common.mk
# Override paths after common vars are defined
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/.testing
SUBMISSION_DIR := $(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/test_submissions
ERRORS_DIR := $(ASSIGNMENT_DIR)/errors
AUTOGRADER_DIR := $(ASSIGNMENT_DIR)/Gradescope_Autograder_Template

.PHONY: submit
submit:
	@set +e; \
	mkdir -p "$(SUBMISSION_DIR)"; \
	ts=$$(date +"%Y%m%d-%H%M%S"); \
	submission_zip="$(SUBMISSION_DIR)/submission_test.zip"; \
	failed_dir="$(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/failed tests"; \
	rm -f "$$submission_zip"; \
	(cd "$(ASSIGNMENT_DIR)" && zip -rq "$$submission_zip" . -x "errors" "errors/*" "Gradescope_Autograder_Template/failed tests" "Gradescope_Autograder_Template/failed tests/*"); \
	echo "[TEST] Primary Dependency: iVerilog"; \
	tmpdir=$$(mktemp -d); \
	primary_status="pass"; \
	run_mux() { \
	  name="$$1"; tb="$$2"; src="$$3"; \
	  sanitized_name=$$(printf '%s' "$$name" | tr ' ' '_'); \
	  out="$$tmpdir/$$sanitized_name.out"; \
	  if iverilog -g2012 -o "$$out" "$(ASSIGNMENT_DIR)/$$src" "$(ASSIGNMENT_DIR)/$$tb"; then \
	    sim_out=$$(vvp "$$out" 2>&1); \
	    sim_rc=$$?; \
	    if [ $$sim_rc -eq 0 ]; then \
	      echo "  [OK] $$name"; \
	    else \
	      echo "  [FAIL] $$name (simulation)"; \
	      printf "%s\n" "$$sim_out" | sed 's/^/    /'; \
	      primary_status="fail"; \
	    fi; \
	  else \
	    echo "  [FAIL] $$name (compile)"; primary_status="fail"; \
	  fi; \
	}; \
	run_mux "Continuous mux" "tb_mux2_continuous.v" "mux2_continuous.v"; \
	run_mux "Procedural mux" "tb_mux2_procedural.v" "mux2_procedural.v"; \
	if ! command -v docker >/dev/null 2>&1; then \
	  echo "  [FAIL] Autograder setup (docker not available in PATH)"; \
	  primary_status="fail"; \
	else \
	  autolog=$$(mktemp); \
	  if (cd "$(AUTOGRADER_DIR)" && ./run setup >"$$autolog" 2>&1); then \
	    echo "  [OK] Autograder setup"; \
	  else \
	    echo "  [FAIL] Autograder setup"; \
	    sed 's/^/    /' "$$autolog"; \
	    primary_status="fail"; \
	  fi; \
	  if [ "$$primary_status" = "pass" ]; then \
	    if (cd "$(AUTOGRADER_DIR)" && ./run grade "./test_submissions/submission_test.zip" >>"$$autolog" 2>&1); then \
	      echo "  [OK] Autograder grade"; \
	    else \
	      echo "  [FAIL] Autograder grade"; \
	      sed 's/^/    /' "$$autolog"; \
	      primary_status="fail"; \
	    fi; \
	  else \
	    echo "  [SKIP] Autograder grade (setup failed)"; \
	  fi; \
	  rm -f "$$autolog"; \
	fi; \
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
	rm -rf "$$tmpdir"; \
	if [ "$$primary_status" = "pass" ]; then \
	  rm -f "$$submission_zip"; \
	else \
	  mkdir -p "$$failed_dir"; \
	  mv -f "$$submission_zip" "$$failed_dir/" 2>/dev/null || true; \
	fi; \
	if [ "$$secondary_status" != "pass" ]; then exit 1; fi; \
	if [ "$$primary_status" != "pass" ]; then exit 1; fi
