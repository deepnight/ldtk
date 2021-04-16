# Deploy instructions

## Preparation & checks
- [ ] Define a GITHUB_TOKEN env var
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

## Prepare GitHub release
- [ ] Run `npm run publish-github`
- [ ] Copy *Releases notes* to GitHub
- [ ] Build macOS and Linux distribs
- [ ] Attach macOS to GitHub Release
- [ ] Attach Linux to GitHub Release

## Docs
- [ ] Build QuickType files
- [ ] Upload Changelog to FTP
- [ ] Upload JSON Doc to FTP
- [ ] Upload JSON Schema to FTP
- [ ] Upload QuickType parsers

## Publish
- [ ] Upload HaxeLib
- [ ] Add "x.x.x-rcX" tag to Haxe API repo
- [ ] Run `npm run publish-itchio`
- [ ] Upload macOS build to Itch.io
- [ ] Upload Linux build to Itch.io
- [ ] Publish GitHub release
- [ ] *[Optional]* Update Itch.io page

## Communication
- [ ] Add a devlog post on Itch.io
- [ ] Announce on Twitter
- [ ] Announce on Discord
- [ ] Announce on Reddit (major releases only)
