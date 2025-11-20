## [Unreleased]

### Added

- Automatic package manager detection from lockfiles when `packageManager` property is not set. Detection priority: `bun.lockb`, `pnpm-lock.yaml`, `yarn.lock` (with automatic Yarn Berry vs Classic detection), `package-lock.json`. Falls back to `PACKAGE_JSON_FALLBACK_MANAGER` environment variable or npm when no lockfile is found ([PR 42](https://github.com/shakacode/package_json/pull/42) by [justin808](https://github.com/justin808))

## [0.2.0] - 2025-11-06

### Added

- Add support for `exact` parameter in `add` method to install packages with
  exact versions ([#29](https://github.com/shakacode/package_json/pull/29))

### Fixed

- Ensure RBS for `PackageJson` class is correct
  ([#39](https://github.com/shakacode/package_json/pull/39))

## [0.1.1] - 2025-11-04

### Changed

- Strip ANSI/CSI escape sequences when fetching `yarn bin` path
  ([#31](https://github.com/shakacode/package_json/pull/31))

## [0.1.0] - 2023-09-15

- Initial release
