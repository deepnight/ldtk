# 1.0.0

## First LDTK-Smartive release

### Smartive versioning

- Started an independent LDTK-Smartive release line at `1.0.0`.
- The application, installers, release titles, and update metadata now use the Smartive version.
- Kept the LDtk project JSON compatibility version independent at `1.5.3`, so opening and saving existing LDtk projects does not trigger false migrations or downgrade their format version.
- Added stable SemVer release tags in the form `v1.0.0`, `v1.0.1`, `v1.1.0`, and so on.
- Added Windows update metadata so installed Windows builds can detect and install later Smartive releases.
- macOS and Linux builds check the Smartive GitHub releases page for later versions.

### Fork features included

- Auto-place configured child entities when a parent entity is created.
- Apply configured child offsets and automatically populate compatible parent `EntityRef` fields.
- Import `.aseprite` tilesets with a layer picker so gameplay art can be selected without normal-map, emission, or other auxiliary layers.
- Include the cumulative editor-preview, animated-tile, atlas-composer, and authoring-tool changes currently present in the fork branch.

### Builds

- Windows x64 installer.
- Universal macOS DMG.
- Linux x64 AppImage.
