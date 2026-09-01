# LDTK-Smartive versioning

LDTK-Smartive uses an independent stable Semantic Versioning sequence beginning at `1.0.0`.

## Two separate versions

- `app/package.json` is the source of truth for the **LDTK-Smartive application and release version**.
- `docs/version.txt` is the **upstream LDtk JSON compatibility version**. It remains `1.5.3` until the fork intentionally adopts a newer LDtk project format.

Do not change `docs/version.txt` for a normal Smartive patch, minor, or major release. Keeping these values separate prevents Smartive `1.x` builds from treating LDtk `1.5.3` projects as old-format files.

## Create the next version

Run commands from the `app` directory:

```bash
npm run version:patch
npm run version:minor
npm run version:major
npm run version:set -- 1.2.3
```

The bump tool updates `app/package.json`, updates `app/package-lock.json` if one exists, and creates a new section at the top of `docs/SMARTIVE_CHANGELOG.md`.

Replace the generated `TODO` changelog line before publishing. The release workflow rejects missing, empty, or unfinished changelog sections.

## Publish

Commit the version and changelog changes on a feature branch, then merge that branch into the default `master` branch.

The release workflow runs from `master`, reads the version from `app/package.json`, validates it, and publishes only when the corresponding stable tag does not already exist. It is triggered when the application version, Smartive changelog, or release workflow changes on `master`. This also means a changelog-only correction can restart a release that previously failed validation.

Releases use tags such as:

```text
v1.0.0
v1.0.1
v1.1.0
v2.0.0
```

Each release contains:

- Windows x64 installer, `latest.yml`, and blockmap metadata for automatic updates.
- Universal macOS DMG.
- Linux x86_64 AppImage.

A manual workflow dispatch can force a rebuild of the current version when an interrupted or damaged release must be replaced. Normal development commits do not create releases unless the package version or its changelog section changes.
