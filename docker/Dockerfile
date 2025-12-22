FROM ubuntu:24.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    iverilog \
    make \
    git \
    bash \
    ca-certificates \
    zip \
    python3 \
    python3-pip \
    python3-diff-match-patch && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /repo
