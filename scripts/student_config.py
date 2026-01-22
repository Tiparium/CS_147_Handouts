#!/usr/bin/env python3
import argparse
import json
import os
import sys
from typing import Any, Dict


def load_config(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_config(path: str, data: Dict[str, Any]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def get_student(data: Dict[str, Any]) -> Dict[str, Any]:
    student = data.get("student", {})
    current = student.get("current_name")
    prev = student.get("previous_names", [])
    if not isinstance(prev, list):
        prev = []
    return {"current": current, "previous": prev}


def set_student(data: Dict[str, Any], name: str) -> Dict[str, Any]:
    student = data.get("student", {})
    prev = student.get("previous_names", [])
    if not isinstance(prev, list):
        prev = []
    current = student.get("current_name")
    if current and current != name and current not in prev:
        prev.append(current)
    student["current_name"] = name
    student["previous_names"] = prev
    data["student"] = student
    return data


def clear_student(data: Dict[str, Any]) -> Dict[str, Any]:
    data = dict(data)
    data.pop("student", None)
    return data


def cmd_current(args):
    data = load_config(args.config)
    info = get_student(data)
    if info["current"]:
        print(info["current"])
    return 0


def cmd_set(args):
    if not args.name:
        print("Name cannot be empty.", file=sys.stderr)
        return 1
    data = load_config(args.config)
    data = set_student(data, args.name)
    save_config(args.config, data)
    return 0


def cmd_summary(args):
    data = load_config(args.config)
    info = get_student(data)
    current = info["current"] or "(not set)"
    prev = info["previous"]
    print(f"Current name: {current}")
    if prev:
        print("Previous names: " + ", ".join(prev))
    else:
        print("Previous names: none")
    return 0


def cmd_clear_student(args):
    data = load_config(args.config)
    data = clear_student(data)
    save_config(args.config, data)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Manage student config.")
    parser.add_argument("--config", default="config.json", help="Path to config.json")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_current = sub.add_parser("current", help="Print current student name if set")
    p_current.set_defaults(func=cmd_current)

    p_set = sub.add_parser("set", help="Set student name (tracks previous)")
    p_set.add_argument("--name", required=True, help="Student name")
    p_set.set_defaults(func=cmd_set)

    p_summary = sub.add_parser("summary", help="Show current and previous names")
    p_summary.set_defaults(func=cmd_summary)

    p_clear = sub.add_parser("clear-student", help="Remove student info from config")
    p_clear.set_defaults(func=cmd_clear_student)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
