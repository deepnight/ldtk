# About

L-Ed is a **modern**, **lightweight** and **open-source** 2D level editor.

Links: [Official website](https://deepnight.net/tools/led-2d-level-editor/) | [Haxe API (on GitHub)](https://github.com/deepnight/led-haxe-api)

[![Build Status](https://travis-ci.com/deepnight/led.svg?branch=master)](https://travis-ci.com/deepnight/led)

# Building from source

## Requirements

 - **[Haxe compiler](https://haxe.org)**: you need an up-to-date and working Haxe install to build L-Ed.
 - **[NPM](https://www.npmjs.com/)**: this package manager is used for various install and packaging scripts

### Installing Haxe libs

Install required haxe libs:
```
haxelib git heaps https://github.com/HeapsIO/heaps.git

haxelib git hxnodejs https://github.com/HaxeFoundation/hxnodejs.git

haxelib git electron https://github.com/tong/hxelectron.git

haxelib git deepnightLibs https://github.com/deepnight/deepnightLibs.git

haxelib git castle https://github.com/ncannasse/castle.git
```

### Installing Node dependencies

```
npm i --prefix app
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

```
npm start --prefix app
```

# Related tools & licences

 - Tileset images: see [README](app/samples/README.md) in samples
 - Haxe: https://haxe.org/
 - Heaps.io: https://heaps.io/
 - Electron: https://www.electronjs.org/
 - JQuery: https://jquery.com
 - MarkedJS: https://github.com/markedjs/marked
 - SVG icons from https://material.io
