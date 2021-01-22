# Deploy instructions

This document is for my personal use only, so I don't forget anything ;)

## Preparation & checks
- Run Haxe API tests
- Build Haxe API samples
- Check JSON doc

## Git
- Merge LDtk repo to `master`
- Merge LDtk Haxe API repo to `master`
- Update `Haxelib.json`

## Deploy
- Run `npm run publish-github`
- Copy *Releases notes* to GitHub
- Build macOS and Linux distribs
- Attach them to GitHub Release

## Publish
- Upload HaxeLib
- Upload itch.io build
- Upload macOS and Linux builds to Itch.io
- Upload Changelog to FTP
- Upload JSON Schema to FTP
- Publish GitHub release

## Finalize
- Update Itch.io page