FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_VERSION=18
ARG PNPM_VERSION=9.12.3
ARG FLUTTER_VERSION=3.24.3
ARG FLUTTER_CHANNEL=stable

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/usr/local/flutter \
    PATH=/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:/home/vscode/.local/share/pnpm:/usr/local/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip xz-utils zip libglu1-mesa libgtk-3-0 \
    libstdc++6 libglu1-mesa-dev clang cmake ninja-build pkg-config libgtk-3-dev \
    liblzma-dev libxcursor1 libxdamage1 libxrandr2 libxi6 libgbm1 libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Node.js + pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && corepack enable \
    && npm i -g pnpm@${PNPM_VERSION} firebase-tools@13 \
    && pnpm config set store-dir /home/vscode/.pnpm-store

# Flutter SDK
RUN git clone -b ${FLUTTER_CHANNEL} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && ${FLUTTER_HOME}/bin/flutter config --no-analytics \
    && ${FLUTTER_HOME}/bin/flutter precache --web \
    && chown -R vscode:vscode ${FLUTTER_HOME}

# Chrome for Flutter web (headless)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-signing-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

USER vscode
RUN flutter --version \
    && dart --version \
    && pnpm --version \
    && firebase --version || true

WORKDIR /workspaces

