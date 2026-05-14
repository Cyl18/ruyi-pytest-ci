#!/usr/bin/env bash

set -euo pipefail

LIBGIT2_VERSION="${LIBGIT2_VERSION:-1.9.2}"
LIBGIT2_WORK_DIR=""

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

install_build_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      gcc g++ cmake pkg-config wget \
      libffi-dev libssl-dev libssh2-1-dev zlib1g-dev
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y \
      gcc gcc-c++ cmake pkgconf-pkg-config wget \
      libffi-devel openssl-devel libssh2-devel zlib-devel http-parser-devel
  elif command -v pacman >/dev/null 2>&1; then
    pacman --noconfirm -Sy --needed \
      base-devel cmake pkgconf wget \
      libffi openssl libssh2 zlib http-parser
  else
    log "Unsupported package manager in container"
    return 1
  fi
}

main() {
  local build_dir
  local archive

  if [[ "$(uname -m)" != "riscv64" ]]; then
    log "Skipping libgit2 source build for $(uname -m)"
    return 0
  fi

  if pkg-config --exists libgit2 && [[ "$(pkg-config --modversion libgit2)" == "${LIBGIT2_VERSION}" ]]; then
    log "libgit2 ${LIBGIT2_VERSION} already installed"
    return 0
  fi

  LIBGIT2_WORK_DIR="$(mktemp -d)"
  build_dir="${LIBGIT2_WORK_DIR}/libgit2-${LIBGIT2_VERSION}"
  archive="${LIBGIT2_WORK_DIR}/libgit2-${LIBGIT2_VERSION}.tar.gz"
  trap 'rm -rf "${LIBGIT2_WORK_DIR:-}"' EXIT

  log "Installing libgit2 ${LIBGIT2_VERSION} from source"
  install_build_deps
  wget -q "https://github.com/libgit2/libgit2/archive/refs/tags/v${LIBGIT2_VERSION}.tar.gz" -O "${archive}"
  tar -xzf "${archive}" -C "${LIBGIT2_WORK_DIR}"
  cmake -S "${build_dir}" -B "${build_dir}/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DUSE_HTTP_PARSER=builtin \
    -DBUILD_TESTS=OFF
  cmake --build "${build_dir}/build" --parallel "$(nproc)"
  cmake --install "${build_dir}/build"
  ldconfig
}

main "$@"
