## Tools
- [ ] Define a `GH_TOKEN` env var  ([link](https://github.com/settings/tokens))
- [ ] Install "**Itch.io Butler**" ([download](https://itchio.itch.io/butler)) & login (`butler login`, [doc](https://itch.io/docs/butler/))
- [ ] Add butler to env `PATH`
- [ ] Add code signing files to env
- [ ] Check code signing exp. date: 2025-02-21

## Preparation & checks
- [ ] Verify planned deprecations
- [ ] Fill changelog
- [ ] Rebuild all LDtk sample maps
- [ ] Update Haxe API sample maps
- [ ] Check JSON doc (changed/added flags etc.)
- [ ] Run Haxe API tests
- [ ] Build Haxe API samples

## Git
- [ ] Merge LDtk repo to `master`
- [ ] Merge LDtk Haxe API repo to `master`
- [ ] Update `Haxelib.json`
- [ ] Update branch names in `setup.hxml`

## Prepare GitHub release
- [ ] Run `npm run publish-github`
- [ ] Copy *Releases notes* to GitHub ([link](https://github.com/deepnight/ldtk/releases))
- [ ] Build macOS and Linux distribs
- [ ] Attach macOS to GitHub Release
- [ ] Attach Linux to GitHub Release

## Docs
- [ ] Build QuickType files
- [ ] Upload Changelog to FTP
- [ ] Upload Changelog images to FTP
- [ ] Upload JSON Doc to FTP
- [ ] Upload JSON Schema to FTP
- [ ] Upload QuickType parsers
- [ ] Check "next" folder on FTP
- [ ] Archive docs to the `docs/archives/x.x.x/` folder

## Publish
- [ ] Upload HaxeLib ([check](https://lib.haxe.org/p/ldtk-haxe-api/))
- [ ] Add "x.x.x-rcX" tag to Haxe API repo
- [ ] Run `npm run publish-itchio`
- [ ] Upload macOS build to Itch.io ([link](https://itch.io/dashboard))
- [ ] Upload Linux build to Itch.io
- [ ] Publish GitHub release
- [ ] *[Optional]* Update Itch.io page

## Community APIs
- [ ] Update API list ([issue](https://github.com/deepnight/ldtk/issues/273))

## Communication
- [ ] Add a devlog post on Itch.io
- [ ] Announce on Twitter
- [ ] Announce on Discord
- [ ] Announce on Reddit (major releases only)
