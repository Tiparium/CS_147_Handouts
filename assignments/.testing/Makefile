ASSIGNMENT_NAME := testing
CUSTOM_SUBMIT := 1
include ../assignment-common.mk
# Override paths after common vars are defined
ASSIGNMENT_DIR := $(ASSIGNMENTS_ROOT)/.testing
SUBMISSION_DIR := $(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/test_submissions
ERRORS_DIR := $(ASSIGNMENT_DIR)/errors
AUTOGRADER_DIR := $(ASSIGNMENT_DIR)/Gradescope_Autograder_Template
WAVES_DIR := $(ASSIGNMENT_DIR)/waves

.PHONY: submit
submit:
	@set +e; \
	mkdir -p "$(SUBMISSION_DIR)"; \
	ts=$$(date +"%Y%m%d-%H%M%S"); \
	submission_zip="$(SUBMISSION_DIR)/submission_test.zip"; \
	failed_dir="$(ASSIGNMENT_DIR)/Gradescope_Autograder_Template/failed tests"; \
	rm -f "$$submission_zip"; \
	(cd "$(ASSIGNMENT_DIR)" && zip -rq "$$submission_zip" . -x "errors" "errors/*" "Gradescope_Autograder_Template/failed tests" "Gradescope_Autograder_Template/failed tests/*"); \
	tmpdir=$$(mktemp -d); \
	run_with_spinner() { \
	  label="$$1"; shift; \
	  start_ts=$$(date +%s); \
	  i=0; \
	  "$$@" & \
	  cmd_pid=$$!; \
	  while kill -0 "$$cmd_pid" 2>/dev/null; do \
	    elapsed=$$(( $$(date +%s) - start_ts )); \
	    mins=$$((elapsed / 60)); secs=$$((elapsed % 60)); \
	    case $$i in \
	      0) spin_char='|' ;; \
	      1) spin_char='/' ;; \
	      2) spin_char='-' ;; \
	      3) spin_char='\\' ;; \
	    esac; \
	    printf "\r  [INFO] %s: %s %02d:%02d" "$$label" "$$spin_char" "$$mins" "$$secs"; \
	    i=$$(( (i + 1) % 4 )); \
	    sleep 0.2; \
	  done; \
	  wait "$$cmd_pid"; rc=$$?; \
	  printf "\r"; \
	  return $$rc; \
	}; \
	section() { \
	  name="$$1"; status_var="$$2"; shift 2; \
	  eval "$$status_var=pass"; \
	  echo "[TEST] $$name"; \
	  "$$@"; \
	  status_val=$$(eval "echo \$$$${status_var}"); \
	  status_upper=$$(printf '%s' "$$status_val" | tr '[:lower:]' '[:upper:]'); \
	  echo "  [Result: $$status_upper]"; \
	  echo ""; \
	}; \
	run_mux_tests() { \
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
	    if run_with_spinner "Autograder setup" sh -c "cd \"$(AUTOGRADER_DIR)\" && ./run setup >\"$$autolog\" 2>&1"; then \
	      reuse_note=""; \
	      if grep -qi "already exists; reusing" "$$autolog"; then \
	        reuse_note=" (Reusing existing Docker container)"; \
	      fi; \
	      printf "\r"; \
	      echo "  [OK] Autograder setup$$reuse_note"; \
	    else \
	      printf "\r"; \
	      echo "  [FAIL] Autograder setup"; \
	      sed 's/^/    /' "$$autolog"; \
	      primary_status="fail"; \
	    fi; \
	    if [ "$$primary_status" = "pass" ]; then \
	      if run_with_spinner "Autograder grade" sh -c "cd \"$(AUTOGRADER_DIR)\" && ./run grade \"./test_submissions/submission_test.zip\" >>\"$$autolog\" 2>&1"; then \
	        printf "\r"; \
	        echo "  [OK] Autograder grade"; \
	      else \
	        printf "\r"; \
	        echo "  [FAIL] Autograder grade"; \
	        sed 's/^/    /' "$$autolog"; \
	        primary_status="fail"; \
	      fi; \
	    else \
	      echo "  [SKIP] Autograder grade (setup failed)"; \
	    fi; \
	    rm -f "$$autolog"; \
	  fi; \
	}; \
	run_secondary() { \
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
	}; \
	section "Primary Dependency: iVerilog" primary_status run_mux_tests; \
	section "Secondary Dependencies" secondary_status run_secondary; \
	rm -rf "$$tmpdir"; \
	if [ "$$primary_status" = "pass" ]; then \
	  rm -f "$$submission_zip"; \
	else \
	  mkdir -p "$$failed_dir"; \
	  mv -f "$$submission_zip" "$$failed_dir/" 2>/dev/null || true; \
	fi; \
	if [ "$$secondary_status" != "pass" ]; then exit 1; fi; \
	if [ "$$primary_status" != "pass" ]; then exit 1; fi

.PHONY: waves
waves:
	@set -e; \
	mkdir -p "$(WAVES_DIR)"; \
	echo "Generating waveforms in $(WAVES_DIR)..."; \
	iverilog -g2012 -D DUMP -D DUMPFILE_CONT=\"$(WAVES_DIR)/mux2_continuous.vcd\" -o "$(WAVES_DIR)/cont.out" "$(ASSIGNMENT_DIR)/mux2_continuous.v" "$(ASSIGNMENT_DIR)/tb_mux2_continuous.v"; \
	vvp "$(WAVES_DIR)/cont.out" >/dev/null; \
	iverilog -g2012 -D DUMP -D DUMPFILE_PROC=\"$(WAVES_DIR)/mux2_procedural.vcd\" -o "$(WAVES_DIR)/proc.out" "$(ASSIGNMENT_DIR)/mux2_procedural.v" "$(ASSIGNMENT_DIR)/tb_mux2_procedural.v"; \
	vvp "$(WAVES_DIR)/proc.out" >/dev/null; \
	rm -f "$(WAVES_DIR)/cont.out" "$(WAVES_DIR)/proc.out"; \
	echo "Waveforms ready:"; \
	ls -1 "$(WAVES_DIR)"/*.vcd
