## Tools
- [ ] Define a `GH_TOKEN` env var  ([link](https://github.com/settings/tokens?type=beta), all repo, Actions+Contents)
- [ ] Install "**Itch.io Butler**" ([download](https://itchio.itch.io/butler)) & login (`butler login`, [doc](https://itch.io/docs/butler/))
- [ ] Add butler to env `PATH`
- [ ] Add code signing files to env
- [ ] Check code signing exp. date: 2025-02-21

## Testing
- [ ] Add API unit tests for all new features
- [ ] Update LDtk sample maps
- [ ] Update Haxe API maps
- [ ] Run Haxe API tests
- [ ] Build Haxe API samples
- [ ] Verify GameBase compatibility
- [ ] Pack a local Setup and test it

## Preparation
- [ ] Check the issues in the Pending milestone ([pendings](https://github.com/deepnight/ldtk/milestone/28))
- [ ] Verify planned deprecations
- [ ] Fill changelog
- [ ] Check JSON doc (changed/added flags etc.)
- [ ] Build QuickType files

## Git
- [ ] Merge LDtk repo to `master`
- [ ] Merge LDtk Haxe API repo to `master`
- [ ] Update `Haxelib.json`
- [ ] Update branch names in `setup.hxml`

## Prepare GitHub release
- [ ] Run `npm run publish-github`
- [ ] Copy *Releases notes* to GitHub ([link](https://github.com/deepnight/ldtk/releases))
- [ ] Build macOS and Linux distribs ([link](https://github.com/deepnight/ldtk/actions))
- [ ] Attach macOS to [GitHub Release]([link](https://github.com/deepnight/ldtk/releases))
- [ ] Attach Linux to [GitHub Release]([link](https://github.com/deepnight/ldtk/releases))

## Docs
- [ ] Upload *Changelog*, *Changelog images*, *JSON doc*, *JSON schema* to FTP
- [ ] Upload QuickType parsers
- [ ] Check and update "next" folder on FTP

## Publish Haxe API
- [ ] Submit to LDtk Haxe API HaxeLib ([check](https://lib.haxe.org/p/ldtk-haxe-api/))
- [ ] Add "x.x.x-rcX" tag to Haxe API repo

## Publish Itch
- [ ] Run `npm run publish-itchio`
- [ ] Upload macOS build to Itch.io ([link](https://itch.io/dashboard))
- [ ] Upload Linux build to Itch.io ([link](https://itch.io/dashboard))
- [ ] Add a devlog post on Itch.io ([link](https://deepnight.itch.io/ldtk))
- [ ] *[Optional]* Update Itch.io page

## Release
- [ ] Publish GitHub release
- [ ] Publish the devlog post on Itch.io ([devLogs](https://itch.io/dashboard/game/740403/devlog))

## Community APIs
- [ ] Update website API list ([issue](https://github.com/deepnight/ldtk/issues/273))

## Communication
- [ ] Announce on Twitter
- [ ] Announce on Discord
- [ ] Announce on Reddit (major releases only)

## Archives
- [ ] Archive installer to FTP
- [ ] Archive docs to the `docs/archives/x.x.x/` folder
