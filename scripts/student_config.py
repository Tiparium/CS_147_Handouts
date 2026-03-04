#!/usr/bin/env python3
import argparse
import json
import sys
from typing import Any, Dict, Optional


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
    current_id = student.get("current_id")
    prev = student.get("previous_names", [])
    prev_ids = student.get("previous_ids", [])
    if not isinstance(prev, list):
        prev = []
    if not isinstance(prev_ids, list):
        prev_ids = []
    return {
        "current_name": current,
        "current_id": current_id,
        "previous_names": prev,
        "previous_ids": prev_ids,
    }


def set_student(data: Dict[str, Any], name: Optional[str] = None, student_id: Optional[str] = None) -> Dict[str, Any]:
    student = data.get("student", {})
    prev = student.get("previous_names", [])
    prev_ids = student.get("previous_ids", [])
    if not isinstance(prev, list):
        prev = []
    if not isinstance(prev_ids, list):
        prev_ids = []

    current_name = student.get("current_name")
    current_id = student.get("current_id")

    if name is not None:
        if current_name and current_name != name and current_name not in prev:
            prev.append(current_name)
        student["current_name"] = name

    if student_id is not None:
        if current_id and current_id != student_id and current_id not in prev_ids:
            prev_ids.append(current_id)
        student["current_id"] = student_id

    student["previous_names"] = prev
    student["previous_ids"] = prev_ids
    data["student"] = student
    return data


def clear_student(data: Dict[str, Any]) -> Dict[str, Any]:
    data = dict(data)
    data.pop("student", None)
    return data


def cmd_current(args):
    data = load_config(args.config)
    info = get_student(data)
    if info["current_name"]:
        print(info["current_name"])
    return 0


def cmd_current_id(args):
    data = load_config(args.config)
    info = get_student(data)
    if info["current_id"]:
        print(info["current_id"])
    return 0


def cmd_set(args):
    if args.name is None and args.student_id is None:
        print("At least one of --name or --id must be provided.", file=sys.stderr)
        return 1
    if args.name is not None and not args.name:
        print("Name cannot be empty.", file=sys.stderr)
        return 1
    if args.student_id is not None:
        if not args.student_id.isdigit() or len(args.student_id) != 9:
            print("Student ID must be exactly 9 numeric digits.", file=sys.stderr)
            return 1
    data = load_config(args.config)
    data = set_student(data, name=args.name, student_id=args.student_id)
    save_config(args.config, data)
    return 0


def cmd_summary(args):
    data = load_config(args.config)
    info = get_student(data)
    current_name = info["current_name"] or "(not set)"
    current_id = info["current_id"] or "(not set)"
    prev_names = info["previous_names"]
    prev_ids = info["previous_ids"]
    print("Student profile:")
    print(f"  Current name: {current_name}")
    print(f"  Student ID: {current_id}")
    if prev_names:
        print("  Previous names: " + ", ".join(prev_names))
    else:
        print("  Previous names: none")
    if prev_ids:
        print("  Previous IDs: " + ", ".join(prev_ids))
    else:
        print("  Previous IDs: none")
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

    p_current_id = sub.add_parser("current-id", help="Print current student ID if set")
    p_current_id.set_defaults(func=cmd_current_id)

    p_set = sub.add_parser("set", help="Set student profile fields (tracks previous values)")
    p_set.add_argument("--name", help="Student name")
    p_set.add_argument("--id", dest="student_id", help="Student ID (exactly 9 digits)")
    p_set.set_defaults(func=cmd_set)

    p_summary = sub.add_parser("summary", help="Show student profile summary")
    p_summary.set_defaults(func=cmd_summary)

    p_clear = sub.add_parser("clear-student", help="Remove student info from config")
    p_clear.set_defaults(func=cmd_clear_student)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
