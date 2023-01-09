# About

![](https://github.com/deepnight/ldtk/blob/master/app/assets/img/LDtk.svg)

**Level Designer Toolkit** (*LDtk*) is a **modern**, **efficient** and **open-source** 2D level editor with a strong focus on user-friendliness.

Links: [Official website](https://ldtk.io/) | [Haxe API (on GitHub)](https://github.com/deepnight/ldtk-haxe-api)

[![GitHub Repo stars](https://img.shields.io/github/stars/deepnight/ldtk?color=%23dca&label=%E2%AD%90)](https://github.com/deepnight/ldtk)
[![GitHub All Releases](https://img.shields.io/github/downloads/deepnight/ldtk/total?color=%2389b&label=Downloads)](https://github.com/deepnight/ldtk/releases/latest)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/deepnight/ldtk/test-windows.yml?label=LDtk%20build)](https://github.com/deepnight/ldtk/actions/workflows/test-windows.yml)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/deepnight/ldtk-haxe-api/unitTests.yml?label=Unit%20tests)](https://github.com/deepnight/ldtk-haxe-api/actions/workflows/unitTests.yml)

# Getting LDtk latest version

Visit [LDtk.io](https://ldtk.io) to get latest version.

# Building from source

## Requirements

- **[Haxe compiler](https://haxe.org)**: you need an up-to-date and working Haxe install  to build LDtk.
- **[NPM](https://nodejs.org/en/download/)**: this package manager is used for various install and packaging scripts. It is packaged with NodeJS.

## Compiling another branch

If you want to try a future version of LDtk, you can checkout branches named `dev-x.y.z` where x.y.z is version number e.g. `dev-1.2.3`

**IMPORTANT**:
- these *dev* branches might be unstables, or even broken. Therefore, it's not recommended to use, unless you plan to add or fix something on LDtk.
- because *dev* branches might change quickly, you will need to update haxelibs often.
- you will need to switch the *LDtk haxe API* to the **same**/**nearest** branch as LDtk repo. (adapt the branch name below accordingly):

edit this line in setup.hxml
```
--cmd haxelib git ldtk-haxe-api https://github.com/deepnight/ldtk-haxe-api.git dev-1.2.1 --always
```

- Run this in a terminal in the root folder of the repo
```
haxe setup.hxml
```

In vscode to get intilisense make sure to change the haxe configuration to `renderer.debug.hxml`

If you make changes to scss remember to use a compiler such as sass or a vscode extension to compile it to css

## Running

### VScode

Hit `F5` then in vscode and it will compile and run everything in debug mode to start testing

### Cli

in the `ldtk` root folder, run:
```
haxe main.debug.hxml
haxe renderer.debug.hxml
```

in the `app` folder, run:

```
npm run start
```

# Contributing

You can read the general Pull Request guidelines here:
https://github.com/deepnight/ldtk/wiki#pull-request-guidelines

# Related tools & licences

- Tileset images: see [README](app/extraFiles/samples/README.md) in samples
- Haxe: https://haxe.org/
- Heaps.io: https://heaps.io/
- Electron: https://www.electronjs.org/
- JQuery: https://jquery.com
- MarkedJS: https://github.com/markedjs/marked
- SVG icons from https://material.io
- Default palette: "*Endesga32*" by Endesga (https://lospec.com/palette-list/endesga-32)
- Default color blind palette: "*Colorblind 16*" by FilipWorks (https://github.com/filipworksdev/colorblind-palette-16)
