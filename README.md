# About

**Level Designer Toolkit** (*LDtk*) is a **modern**, **efficient** and **open-source** 2D level editor with a strong focus on user-friendliness.

Links: [Official website](https://deepnight.net/tools/ldtk-2d-level-editor/) | [Haxe API (on GitHub)](https://github.com/deepnight/ldtk-haxe-api)

[![Build Status](https://travis-ci.com/deepnight/ldtk.svg?branch=master)](https://travis-ci.com/deepnight/ldtk)

# Building from source

## Requirements

 - **[Haxe compiler](https://haxe.org)**: you need an up-to-date and working Haxe install  to build L-Ed.
 - **[NPM](https://www.npmjs.com/)**: this package manager is used for various install and packaging scripts

### Installing Haxe libs

Install required haxe libs:
```
haxelib git heaps https://github.com/HeapsIO/heaps.git

haxelib git hxnodejs https://github.com/HaxeFoundation/hxnodejs.git

haxelib git electron https://github.com/tong/hxelectron.git

haxelib git deepnightLibs https://github.com/deepnight/deepnightLibs.git

haxelib git ldtk-haxe-api https://github.com/deepnight/ldtk-haxe-api.git

haxelib git castle https://github.com/ncannasse/castle.git
```

### Installing Node dependencies

Run the following command in the `app` folder:
```
npm i
```

## Compiling

First, from the root of the repo, build the electron **Main**:

```
haxe main.debug.hxml
```

This should create a `app/assets/main.js` file.

Then, build the electron **Renderer**:

```
haxe renderer.debug.hxml
```

This should create `app/assets/js/renderer.js`.

## Running

From a command line in the `app` folder, run:

```
npm run start
```

# Related tools & licences

 - Tileset images: see [README](app/samples/README.md) in samples
 - Haxe: https://haxe.org/
 - Heaps.io: https://heaps.io/
 - Electron: https://www.electronjs.org/
 - JQuery: https://jquery.com
 - MarkedJS: https://github.com/markedjs/marked
 - SVG icons from https://material.io
