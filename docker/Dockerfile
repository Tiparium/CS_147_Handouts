FROM ubuntu:24.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    iverilog \
    make \
    git \
    bash \
    ca-certificates \
    zip \
    unzip \
    python3 \
    python3-pip \
    python3-diff-match-patch \
    tree \
    vim \
    docker.io \
    openjdk-17-jre-headless && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /repo

# Custom clear helper: supports numbered blank lines (clear <n> [-nonum])
RUN printf '\n# custom clear helper\nclear() {\n  local count=\"$1\"\n  shift || true\n  if [ -z \"$count\" ]; then\n    command clear\n    return\n  fi\n  local numbered=true\n  for arg in \"$@\"; do\n    if [ \"$arg\" = \"-nonum\" ]; then\n      numbered=false\n    fi\n  done\n  local i\n  for i in $(seq 1 \"$count\"); do\n    if $numbered; then\n      printf \"[%3d]\\n\" \"$i\"\n    else\n      printf \"\\n\"\n    fi\n  done\n}\n' >> /etc/bash.bashrc
