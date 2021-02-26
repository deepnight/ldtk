# Deploy instructions

This document is for my personal use only, so I don't forget anything ;)

## Preparation & checks
- [ ] Verify planned deprecations
- [ ] Fill changelog
- [ ] Update JSON changelog if necessary
- [ ] Run API tests
- [ ] Build API samples
- [ ] Check JSON doc
- [ ] Rebuild LDtk demo maps

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
- [ ] Upload Changelog to FTP
- [ ] Upload JSON Doc to FTP
- [ ] Upload JSON Schema to FTP
- [ ] Upload QuickType parsers
- [ ] Publish GitHub release

## Finalize
- [ ] Update Itch.io page
- [ ] Add a devlog post on Itch.io