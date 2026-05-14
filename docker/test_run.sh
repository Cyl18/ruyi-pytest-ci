#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=/ruyi-pytest-ci
TEST_ROOT="${PROJECT_ROOT}/ruyi-pytest"
ARTIFACTS_DIR=/artifacts
CI_VENV_DIR="${PROJECT_ROOT}/.ci-venv"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

system_python_bin() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    return 1
  fi
}

python_bin() {
  if [[ -x "${CI_VENV_DIR}/bin/python" ]]; then
    printf '%s\n' "${CI_VENV_DIR}/bin/python"
  else
    system_python_bin
  fi
}

install_runtime_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo env DEBIAN_FRONTEND=noninteractive apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bash bzip2 gzip lz4 tar xz-utils zstd unzip ca-certificates \
      file expect git make sudo python3 python3-pip python3-venv \
      libffi-dev libgit2-dev
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y \
      bash bzip2 gzip lz4 tar xz zstd unzip ca-certificates \
      file expect git make sudo python3 python3-pip libffi-devel libgit2-devel
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman --noconfirm -Sy --needed \
      bash bzip2 gzip lz4 tar xz zstd unzip ca-certificates \
      file expect git make sudo python python-pip libffi libgit2
  else
    log "Unsupported package manager in container"
    return 1
  fi
}

prepare_env_file() {
  if [[ -n "${RUYI_REPO:-}" ]]; then
    cat > "${TEST_ROOT}/.env" <<EOF
# Optional mirror selection for CI.
# Valid values: ISCAS, GITEE
RUYI_REPO=${RUYI_REPO}
EOF
  else
    rm -f "${TEST_ROOT}/.env"
  fi
}

install_python_packages() {
  local py

  py="$(system_python_bin)"
  rm -rf "${CI_VENV_DIR}"
  "$py" -m venv "${CI_VENV_DIR}"

  "${CI_VENV_DIR}/bin/python" -m pip install --upgrade pip
  "${CI_VENV_DIR}/bin/python" -m pip install \
    pytest \
    pytest-env \
    pexpect \
    'pygit2<1.19' \
    'ruyi>=0.47.0'
}

main() {
  mkdir -p "${ARTIFACTS_DIR}"
  sudo chown -R "$(id -u):$(id -g)" "${ARTIFACTS_DIR}"
  sudo chmod -R u+rwX "${ARTIFACTS_DIR}"

  log "Installing runtime dependencies"
  install_runtime_deps

  export PATH="${CI_VENV_DIR}/bin:${PATH}"
  export LANG="${LANG:-en_US.UTF-8}"
  export LC_ALL="${LC_ALL:-en_US.UTF-8}"

  install_python_packages
  log "Python runtime: $(python_bin)"
  prepare_env_file

  cd "${TEST_ROOT}"

  log "pytest version: $(python_bin) -m pytest --version"
  "$(python_bin)" -m pytest --version | tee "${ARTIFACTS_DIR}/pytest-version.txt"
  log "ruyi version"
  ruyi --version | tee "${ARTIFACTS_DIR}/ruyi-version.txt"

  log "Running pytest for ${DISTRO_ID:-unknown-distro}"
  "$(python_bin)" -m pytest -ra \
    --junitxml "${ARTIFACTS_DIR}/pytest.xml" \
    ${PYTEST_ARGS:-} \
    2>&1 | tee "${ARTIFACTS_DIR}/pytest.log"
}

main "$@"
