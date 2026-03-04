#!/usr/bin/env bash
set -e

# Install system dependencies needed by most autograders.
# Adjust the package list for assignment-specific tooling.
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
apt-get -qq install -y \
  build-essential \
  python3 python3-pip python-is-python3 \
  dos2unix
