#!/usr/bin/env python3
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def run_test(name, tb, sources):
    with tempfile.TemporaryDirectory() as tmpdir:
        build = pathlib.Path(tmpdir) / f"{name}.out"
        cmd_compile = ["iverilog", "-g2012", "-o", str(build)] + [str(HERE / f) for f in sources] + [str(HERE / tb)]
        comp = run(cmd_compile)
        if comp.returncode != 0:
            return False, f"compile failed: {comp.stderr.strip() or comp.stdout.strip()}"
        sim = run(["vvp", str(build)])
        if sim.returncode != 0:
            return False, sim.stdout.strip() or sim.stderr.strip() or "simulation failed"
        return True, sim.stdout.strip()


def main():
    tests = [
        ("mux2_continuous", "tb_mux2_continuous.v", ["mux2_continuous.v"]),
        ("mux2_procedural", "tb_mux2_procedural.v", ["mux2_procedural.v"]),
    ]
    all_ok = True
    for name, tb, sources in tests:
        ok, msg = run_test(name, tb, sources)
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}: {msg}")
        all_ok = all_ok and ok
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
