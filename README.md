# ruyi-pytest-ci

CI harness for [`ruyi-pytest`](https://github.com/ruyisdk-test/ruyi-pytest).

This repository keeps the multi-distro, multi-architecture GitHub Actions layout
migrated from [`ruyi-litester`](https://github.com/ruyisdk-test/ruyi-litester),
but runs the `ruyi-pytest` test suite from a Git submodule instead.

The report-generation part from `ruyi-litester` is intentionally removed.

## Repository layout

- `ruyi-pytest/` — Git submodule pointing at the upstream test repository
- `docker/` — Dockerfiles and runtime script used by the workflows
- `.github/workflows/` — x86_64 / arm64 / riscv64 workflow definitions

## Notes

- Update the submodule after cloning:

  ```bash
  git submodule update --init --recursive
  ```

- The manual workflows accept an optional `RUYI_REPO` mirror input.
- Raw test artifacts are uploaded, but report generation is not included.
