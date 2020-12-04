# 0.6.2

- Added an optional **Regular Expression** that can be tested against a `String` field in an Entity. Any unmatched character in a string value will just be discarded. This allows the creation of custom field type (that needs to follow some specific pattern), while still having a safety net (the editor cleans up invalid parts).

# 0.6.1

- **New website URL: [LDtk.io](https://ldtk.io)**
- New Json schema URL: [LDtk.io/json](https://ldtk.io/json)
- Updated in-app URLs
- Fixed a crash when editing Entity points and switching layer
- Fixed a crash in Tiled TMX exporter caused by tilesets without image
- Fixed macOS build (didn't start properly).
- Fixed long auto-update error message on Linux and macOS versions.
- Fixed entities being destroyed when dragged near level limits
- Fixed *samples* folder location on macOS
- Updated buttons on app home page
- Minor update to app logo

# 0.6.0 - Take over the world!

## 💬 Discord

We now have an official **Discord**! Come join us, we have cookies 🤗 Feel free to share the invite URL: **https://ldtk.io/go/discord**

## 🌍 World map

Levels in your project can now be organized in various ways:
- freely on a vast 2D map,
- in a large grid system (aka "grid-vania"),
- horizontally,
- vertically.

Just hit the `W` or `F2` key to switch to world view, and start re-arranging your creations as you wish! While in world mode, you can `right click` to reveal a context menu.

## 📑 Other changes

- **New splash screen**: to reduce screen flickering and dirty window flashes on startup, a new splash screen was added, among other minor changes. The app window should now feel a little more "stable".
- **Smooth zooming/panning**: automatic zooming and panning (eg. when pressing `F` key) are now animated and smoother.
- **New rule editor window**: this UI component really needed some love, so it now features a more streamlined interface and a much better integrated help.
- **User settings** are now stored in AppData OS folder to prevent from losing them on each future update. Unfortunately, this will only apply starting from this version, so settings will be reset one last time :) Sorry!
- **End of beta**: LDtk is no longer considered *Beta* as it's now stable & mature enough to be used in production.
- **"File path" field**: this new field type allow you to refer to an external file directly from an Entity instance (many thanks to [Yanrishatum](https://github.com/Yanrishatum)!)
- Many *under-the-hood* optimizations to support the new World map feature.
- Removed the "double" *Fit* mode when pressing `F`. Now pressing this key just fits the whole level in the viewport.
- Unified R & Shift-R shortcuts: just press R to toggle all auto-layers rendering.
- Fixed loading of files with spaces in name, when using file association on Windows
- Better "invalid value" error display in entity fields (previously, you only had `<error>`).
- Application samples will now display a warning if you try to save them (not recommended as they will be overwritten by future app updates).
- Better Entity panel layout
- Better default entity Field naming when creating a new one
- Fixed a bug in Entity panel that went crazy when containing too many entities.
- Sample maps are no longer added to "recent projects" list
- Updated the Enum panel icon.
- Better display of samples in recent files list on app Home.
- Added a "Close" button to Project panel
- Removed "Loaded" useless notification
- You can now right-click external URL links in LDtk to copy them.
- Fixed middle clicks on URL links.
- Fixed many many issues with rules that didn't update properly after some specific changes (eg. perlin, checker mode, modulos etc.)
- Added a "locate project" button to Project panel
- Fixed an infinite loop when resizing a level
- Fixed a bug with files stored in a path containing some special characters (eg. ~ or %)
- Updated the LDtk website
- Updated all sample maps

# 0.5.2-beta

 - Fixed a crash when loading a project with a "lost" tileset image (ie. path not found).
 - Fixed crash window that looped forever
 - Better crash report window

# 0.5.1-beta

 - Added "top-down" sample map
 - Fixed "File not found" message at startup
 - Fixed a potential crash at startup
 - Fixed auto-reloading of modified tileset images
 - Minor bug fixes
 - Updated external libs used by LDtk (Electron, NodeJS etc.)


# 0.5.0-beta - LDtk: it's about tile!

**Level Designer Toolkit** (*LDtk*) is now the new app name :) I hope you'll like it! The logo was updated, as well as source code, GitHub repo and various other things.

Because of the renaming, users of the Haxe API will have to run the following commands:

```
haxelib remove led-haxe-api
haxelib install ldtk-haxe-api
```

You might also need to **manually uninstall any previous installation of LEd**.

 - **Tiles flipping**: in Tile Layers, you can mirror tiles before painting them by pressing `X` or `Y` (or `Z`). This also works from group of tiles.
 - **Tiles stacking**: you can now optionaly *stack multiple tiles in a single cell of a Tile layer*, reducing the need for multiple layers. For example, you could paint a brick wall, then enable stack mode (`T`), and add details like cracks or vines over the same wall. Be careful though: erasing of stacked elements can be tricky, so you should use a mix of multiple layers and stacking to get the best results.
 - **New editing options bar**: *Grid locking*, *Single layer mode* and *Empty space selection* moved to a new more streamlined button bar.
 - **File association**: project files now use the extension `*.ldtk` instead of `*.json`. Therefore, on Windows, double-clicking such files will open the app accordingly. If you prefer the `.json` extension, you can force it in each project settings (but will lose benefit of the file association).
 - **Auto-layer rule preview**: when you move your mouse over a rule, you will now see which cells in the current layer are affected, making their testing *MUCH* easier.
 - **Tiled (TMX) export**: this optional export now generates proper standard tile layers. However, to support LDtk stacked tiles feature (see above), multiple Tiled layers might be generated per single LDtk layer. Also, IntGrid layers are now properly exported to Tiled (as standard tile layers, with an auto-generated tileset image).
 - **New color picker**: it supports copy/paste, manual hex value editing and a much better UI (thanks to [simple-color-picker](https://github.com/superguigui/simple-color-picker)).
 - **Flood-fill fixes**: if you hold `SHIFT` while clicking in a Tile layer, it will flood-fill the area using currently selected tiles (randomly, or by stamping group of tiles, depending on the current mode).
 - **Flood-fill erasing**: just use `SHIFT`+`Right click` to erase a whole contiguous area.
 - The layer Rule editor now overlaps left panel and allows level editing while being open (makes rule testing much easier). Press `Escape` to close it.
 - In Tile layers, you can press `L` to load a saved tileset selection (using `S` key)
 - Renamed the *Level* panel to *World* (for the 0.6.x future update).
 - It's now possible to change the tileset or even the source layer of an Auto-Layer without loosing your rules.
 - **Auto-layer baking**: turn a complex Auto-Layer into a standard Tile layer (think of it as the *flatten* feature in Photoshop). Be careful, it's a one-way operation.
 - Unified "Show/hide grid" and "Grid locking" options. You can now just press `G` to toggle grid (which also implies "grid locking" in supported layer types).
 - All options (such as "Grid on/off", or "Compact panel mode") are now saved to a JSON file in your app folder, in `userSettings/`.
 - Help window is now a side panel.
 - Opaque tiles are detected in tilesets for use in various optimizations (mostly related to the new tile stacking feature).
 - Fixed a crash when deleting IntGrid layer while an AutoLayer uses it as source.
 - Added some colors to UI buttons
 - New exit button icon.

# 0.4.1-beta

 - Fixed a jQuery related crash
 - Smarter extern Enum file update (ie. silent if changes don't break anything).
 - Better logging in case of crash
 - Open/save dialogs are now modal to the application
 - Fixed distorted left panel in new projects

# 0.4.0-beta - Selections

 - Experimental **Ubuntu** and **MacOS** versions (thanks to the community!)
 - **Selections**: you can now select any element in a level by using `ALT` + left click. You can move it around by holding left click. To select a **rectangle area**, use `ALT` + `SHIFT` + left click.
 - **Duplicate**: you can duplicate any element in the level by drag it with `CTRL`+`ALT` keys.

    **NOTE: For now, "undoing" a *selection move or duplication* will require multiple undos (one per affected layer).** Undo/Redo features need a *major* rework, but this will only happen in a future update (see [#151](https://github.com/deepnight/led/issues/151)). Sorry for the inconvenience until this update!

 - **Duplicate definitions**: you can duplicate any *Definition* (layers, enums, entities etc.) by using the new context menu (right click or use "3-dots" buttons) in all panels.
 - **Duplicate rules or rule groups**: another much needed addition.
 - **Multi-lines texts** added to Entity custom field types.
 - **Type conversions**: Entity fields can now be converted to different types (like turning an *Integer* value to a *Float*, or into an *Array*). Some conversions might not be lossless.

 - Renamed the old *Enhance active layer* option to **Single layer mode**
 - `Alt`+`left click` now picks elements in *all* layers. If you have the *Single layer mode* activated (`A` key), it will pick in current layer only.
 - Added an option to allow selection of empty spaces
 - Better mouse coordinates display in editor footer
 - Added *rectangle selection size* to editor footer
 - Use `DELETE` key to delete selected elements
 - Use `CTRL`+`A` shortcut to select everything (limited to current layer in *Single Layer Mode*).
 - Optimized the JSON format to reduce its size (should be approximately 40-50% smaller).
 - Added the up-to-date *JSON format doc* to the app Home page.
 - Added fullscreen button to view Home *changelogs*
 - Pressing `ENTER` on the Home screen now opens last edited map.
 - Side bar is now more compact
 - Better "Enum sync" window
 - Fixed "Enum value in use" detection
 - Removed duplicate sample map file
 - Fixed mouse wheel zoom limits
 - Fixed "color" field size in Entity instance editor when the value wasn't default.
 - Updated help window
 - Pressing `Escape` key now leaves focused inputs first instead of closing panels.
 - Many bug fixes & minor enhancements

# 0.3.2-beta

 - Fixed a crash when resizing level with an Entity having a null Point value
 - Added button icons in Help window

# 0.3.1-beta

 - **Tiled (TMX) export option**: from the project settings (`F1`), check the *Tiled export* option to save Tiled compatible files along with the LEd JSON.

    **DISCLAIMER**: this export is limited because Tiled doesn't support some core features from LEd, like different grid sizes in the same level or Array of properties in Entities. This export is only meant as a short-term solution to quickly load LEd data in a framework only supporting TMX files. See [documentation](https://ldtk.io/docs/general/exporting-tiled-tmx/) for more informations.

 - Better active/inactive visual state for rules and groups of rules in auto-layers
 - Inactive rules are no longer exported in the JSON file
 - Pressing `F` key twice fits the current level in view but with less padding
 - Added an automated JSON format documentation generator (see [JSON_DOC.md](https://github.com/deepnight/led/blob/master/JSON_DOC.md) in sources)
 - Added version badges in the JSON doc to quickly identify changes per versions.
 - Updated home page
 - Updated `sample` maps

# 0.3.0-beta

 - **Group of tiles in auto-layer rules**: this new feature allows you to place larger objects (eg. *a tree, a big rock, etc.*) made of multiple tiles using just auto-layer rules.
 - Added **Modulo** options for auto-layer rules: this allows a rule to only apply every X columns or Y rows.
 - Added **Checker mode** for auto-layer rules: this makes effects like "brick walls" or "Sonic checker effect" possible ;)
 - **Better hot-reloading**: when a tileset images changes on the disk, LEd will automatically remap tile coordinates if the image size changes. This feature now also works to remap auto-layer tiles.
 - **JSON changes**: please check the new [JSON_CHANGELOG.md](https://github.com/deepnight/led/blob/master/JSON_CHANGELOG.md) for up-to-date changes to JSON format.
 - Fixed image import that failed if the image file was standing on a different drive than the project file.
 - Fixed rule `random` function giving identical results for different rules
 - Fixed a crash while editing rules in *pure* auto-layers.
 - Fixed a crash when Undo history reaches its max (might need more rework).
 - Prepared support for Mac & Linux versions
 - Minor fixes for Linux builds
 - Updated `Samples`
 - Bug fixes


# 0.2.1-beta

 - Added `F1`-`F6` key shortcuts for all editor panels
 - Updated JSON file format with some extra dev-friendly values
 - Added a JSON changelog file for devs working on importers
 - Add JSON changelog to app start page

# 0.2.0-beta

 - **Beta version!**: LEd is now stable enough to be used in production and retro-compatibility will be guaranteed from now on.
 - **Radius**: Integer and Float entity fields can now be displayed as a radius around the entity (eg. a "lightRadius" Float value can now be displayed accordingly right in the editor display). See `Samples` for some examples.
 - **Smart color use**: if you have a Color field in an entity, it will be used when displaying various values in the editor (eg. having a "lightColor" field will affect the color of the circle around the entity).
 - Added support for **tile spacing** and **padding** in Tilesets images.
 - Entity **Arrays** can now be sorted manually
 - Entity tiles can now be displayed as "stretched" (default) or "cropped".
 - A preview of the "Perlin noise" is displayed while editing the settings of an auto-layer rule perlin.
 - Added **mouse coords** in the bottom-right corner of the window.
 - Updated appearance of selected entities
 - Added a field display option to use Enum tiles in place of Entity tiles
 - Added a new option for entities with count limits ("move last one instead of adding").
 - "Enhance active layer" option is now false by default (press `A` to toggle)
 - Entities can now be displayed as "Crosses"
 - Various UI fixes in "Compact" mode (when pressing `TAB`)
 - Fixed relative paths remapping when "Saving As" project
 - Fixed level resize issues which moved Entities and their Point fields in a strange way
 - Fixed panels/windows not closing during app update
 - Fixed SaveAs shortcut (`CTRL+SHIFT+S`)
 - Better entity tile picking UI
 - Updated `Samples`
 - Bug fixes

# 0.1.7-alpha

 - **Array of entity fields**: any field type in an Entity can now be an Array. For example, you could have an Array of Enums to represent the items hidden inside a Cratebox entity. See `Samples` for some examples.
 - **Point coordinates & paths**: this new entity field type allows you to pick a grid coordinates. And if you combine this with the new Array support, you can even build paths of points! See `Samples` for some examples.
 - Added a confirmation when trying to update the app while having unsaved changes
 - UI tweaks & fixes
 - Added some click tolerance when picking entities
 - Swapped "Tileset" and "Enum" buttons in main toolbar
 - Fixed an infinite loop on undo/redo in some levels
 - Updated Haxe API
 - Bug fixes

# 0.1.6-alpha

 - **"Pure" auto-layers**: these layers only have rules and use a separate IntGrid layer as source for their value checks. Very useful to have a separate auto-layer that contains drop-shadows of walls, for example. You can have any number of pure auto-layers using the same single IntGrid source.
 - Grid lock (formerly grid snap) now uses `L` key shortcut instead of G
 - Grid visibility can be toggled using `G` key shortcut
 - Added `SHIFT-R` shortcut to show/hide all auto-layers
 - Updated sample projects
 - Updated "help" window
 - Added quick notifications for some user actions
 - Fixed render issues when deleting or updating auto-layer rules
 - Fixed Haxe API issues
 - Fixed bugs
 - Added some internal app logging for debugging purpose (no sensitive data, don't worry)

# 0.1.5-alpha

 - **Auto-layers**: IntGrid layers can now render themselves automatically by drawing tiles based on their content. You can create "patterns of IntGrid values" (called **Rules**) to decide when a specific tile, or group of random tiles, should appear. It can for example be used to:
   - add random grass or rocks on top of platforms,
   - add random ceiling props under platforms,
   - render ground/water/lava area,
   - etc.
 - Auto-layer rules can be organized in groups.
 - *`Samples`*: click on the `Samples` button on home page to load some example projects.
 - **Smarter warning** when deleting something in a panel. ie. If the value you're removing isn't actually used in your project, you will get a "softer" warning.
 - **Large levels optimizations**: started an important rework of the way levels are rendered on-screen to make room for future optimizations on large levels. For now, it's still recommended to work on levels with smaller dimensions.
 - Added a project option to minify the JSON file.
 - Smarter extern Enum sync: the removal of unused enums will be shown as low-risks operations.
 - Added perlin noise support to Auto-layers rules (a rule can apply to only a random area).
 - Changed version number to 0.1.x because no one could stop me from doing it
 - Better element sorting (levels, layers etc.) experience using SortableJS lib
 - Closing a panel with a color picker will now validate color before closing the panel.
 - Better viewport centering when opening a level.
 - Fixed `0-9` keyboard shortcuts while focusing a field
 - Fixed save/load notifications
 - Many UI/UX fixes
 - Bug fixes

# 0.0.4-alpha

 - Added nice **movement animations** to the tool palette when picking a value with the ALT+click shortcut
 - Reworked the code of the tool palette to be much simpler
 - Clicking an existing Entity now automatically picks it
 - Nicer pixel font for Rulers around the level canvas
 - Added **0 to 9 key shortcuts** to quickly select layers
 - Added a convenient Edit link in Entity instance editor
 - Fixed `CTRL-W` shortcut (should only close current app page)
 - Added `CTRL-Q` shortcut to close the app
 - Added `F` shortcut to fit current level in screen
 - Fixed file path display in Enum panel
 - Fixed image path sometime disappearing in Tileset panel
 - Fixed load/save notifications
 - Updated home
 - Many minor **UI polishing**

# 0.0.3-alpha

 - Better **Entity instance fields editor**
 - Better **auto-update UI**
 - Enhanced ALT-click picking cursor
 - Fixed Changelog display on Home page
 - ALT+click picking no longer picks in other layers by default (you can hold `SHIFT` key to pick in any layer)
 - Fixed window closing not working sometimes
 - Added a brief notification when switching layers using picking
 - Code: Electron cleanup

# 0.0.2-alpha

 - **Release notes**: added release notes to app Home page
 - Adjusted grid opacity
 - Bug fixes
 - Dev scripts cleanup

# 0.0.1-alpha

 - **Alpha release**: this version is only for early testing & feedback purpose.
 - **Auto updater**: Added support for built-in Electron auto-updater
 - Packaged app with a NSIS setup
 - Added Changelog doc
 - Code: major GIT repo cleaning
