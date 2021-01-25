# Deploy instructions

This document is for my personal use only, so I don't forget anything ;)

## Preparation & checks
- [ ] Run Haxe API tests
- [ ] Build Haxe API samples
- [ ] Check JSON doc

## Git
- [ ] Merge LDtk repo to `master`
- [ ] Merge LDtk Haxe API repo to `master`
- [ ] Update `Haxelib.json`

## Deploy
- [ ] Run `npm run publish-github`
- [ ] Copy *Releases notes* to GitHub
- [ ] Build macOS and Linux distribs
- [ ] Attach them to GitHub Release
- [ ] Build QuickType files

## Publish
- [ ] Upload HaxeLib
- [ ] Run `npm run publish-itchio`
- [ ] Upload macOS and Linux builds to Itch.io
- [ ] Change display names for manual Itch.io builds
- [ ] Upload Changelog to FTP
- [ ] Upload JSON Schema to FTP
- [ ] Upload QuickType parsers
- [ ] Publish GitHub release

## Finalize
- [ ] Update Itch.io page
- [ ] Add a devlog post on Itch.io