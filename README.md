# About

L-Ed is a **modern**, **lightweight** and **open-source** 2D level editor.

Links: [Official website](https://deepnight.net/tools/led-2d-level-editor/) | [Haxe API (on GitHub)](https://github.com/deepnight/led-haxe-api)

[![Build Status](https://travis-ci.com/deepnight/led.svg?branch=master)](https://travis-ci.com/deepnight/led)

# Building from source

## Requirements

 - **[Haxe compiler](https://haxe.org)**: you need an up-to-date and working Haxe install  to build L-Ed.
 - **[NPM](https://www.npmjs.com/)**: this package manager is used for various install and packaging scripts

Install required haxe libs:
 - `haxelib git heaps https://github.com/HeapsIO/heaps.git`
 - `haxelib git hxnodejs https://github.com/HaxeFoundation/hxnodejs.git`
 - `haxelib git electron https://github.com/tong/hxelectron.git`
 - `haxelib git deepnightLibs https://github.com/deepnight/deepnightLibs.git`

Install all other required dependencies:
 - open a command line inside the `app` folder,
 - run `npm i`

## Compiling

Run either:

 - `haxe app.hxml` (release version)
 - `npm run compile` from the app folder (same effect as above)
 - `haxe app.debug.hxml` (debug version)*
 
## Running

If compilation was successful, you should now have a `main.js` file in the **app/** folder, and a `renderer.js` in **app/js/** folder.

From a command line in **app/** folder, run:

```
npm run start
```
