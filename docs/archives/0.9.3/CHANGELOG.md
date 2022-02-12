# 0.9.3 - Ludum Dare 48 edition

  - **Aseprite support**: you can now load an Aseprite image directly as a tileset or as a level background. It will be automatically reloaded if it changes on the disk, just like any another image.
  - **Level PNG export**: it's now possible to export a single flattened PNG per level, making the "*Easy to integrate with your game engine*"-thing even easier. You can still export one PNG per layer per level if you prefer.
  - Fixed offseted "Close project" button
  - Fixed "textLanguageMode" typo in JSON
  - Minor bug & doc fixes

# 0.9.2

  - Added a tiny "(...)" above entities with fields when they are hidden
  - Fixed "re-open last project" that could sometime reset app settings
  - Fixed rule editor not updating when changing pivot
  - Fixed incorrect "Perlin noise" preview when right click on the Perlin option in Rules panel.
  - Fixed "shrinking" tileset view when panning it
  - Fixed discarded "levelPaths" array when importing OGMO projects

# 0.9.1

  - **Fixed broken "New project" button. Sorry!**
  - Added an option to **re-open last project** when starting LDtk (open Settings with `F12`)
  - Hold `CTRL` to disable preview when moving mouse over auto-layer rules.
  - Fixed missing tooltips in rules panel.
  - Fixed tooltips staying on screen in rules panel.


# 0.9.0 - Biomes and tags

## New features

  - **Optional auto-layer rules**: this new key feature allows to create "biome" and "variations" by defining group of rules that only apply to specific levels. Please check the new sample "`AutoLayers_5_OptionalRules`". How it works: simply right click on a group of rules in the Rules panel to mark it as `Optional`. This group will then be disabled by default everywhere, and you'll be able to manually enable it in some specific levels only.
  - **Tile tags**: you can now associate an Enum to a Tileset, then "paint" values from this Enum freely on each tiles in the tileset. This could be useful to mark collisions, water tiles, surface sounds or whatever tag you could think of. To use this new feature, just open the Tileset panel, select an existing Enum for a tileset, and start tagging directly.
  - **Tile custom data**: you can add totally custom text values to each tile in any tileset. This could be plain text, JSON, XML, etc.
  - **Auto level naming**: you can let LDtk name your level identifiers automatically using a **custom pattern**, as defined from the Project settings panel. Some examples:
    - default pattern "`Level_%idx`" will name levels "Level_0", "Level_1" etc, based on their order of creation (or order in array, in Horizontal/Vertical world layouts)
    - with the pattern `MyLevel_%gx_%gy`, each level will be named using the world grid X/Y coordinates (only applies to GridVania world layouts).
  - **Auto-layers tileset switching**: in each level and for each layer, you can now switch the tileset on-the-fly.
  - Added "Isolated points" as new display option for points in Entities (thanks to *Stuart Adams*)
  - Each **enum value** can now be associated with a custom color for easier reading in the UI.
  - Re-worked the **Rules panel** to have less buttons and lost space. Some actions where moved to the context menu (eg. renaming a group of rules)
  - Array of Points in Entities can now be displayed as "**looping paths**".

## JSON format

 - **WARNING**: last call before the removal of the deprecated value `intGrid` in `Layer instances`! If not done yet, please switch to the `intGridCsv` value. The old value will be removed on 0.10.0 update.
 - Added **tileset tags**: new array `enumTags` in `Tileset definition JSON` (see https://ldtk.io/json/)

## Other

  - Completely reworked the way the "Auto-layer rules" panel was updated. This should reduce UI flickering and slow-downs while editing rules.
  - Tilesets can now be manually sorted in Tilesets panel
  - Added a new "Optional rules" sample map.
  - Double click on Entities to automatically select all their connected Points.
  - Added a one-time "enable backup" recommendation popup for medium/large projects.
  - Added a "Create level" button in world panel.
  - Added an error message when trying to create a new project in an invalid folder.
  - Added a warning notification when moving an Entity or a Point out of level bounds
  - Added a "close" button on Home screen, when in fullscreen mode
  - Added a popup with various options when project saving goes wrong.
  - Increased max width/height for Entities
  - The keyboard shortcut to toggle auto-layers rendering is now `SHIFT-R`.
  - Reduced tile flickering while zooming in/out (this reduction can be disabled from the app settings)
  - Adjusted custom fields scaling policy (especially for multi-lines fields).
  - Disabled level dimming while editing an auto-layer Rule.
  - Extended app logging limit (from 500 to 5000 lines)
  - Fixed default "smart" color of entities. It uses the first color value found among fields, in order of appearance, otherwise it defaults to entity main color.
  - Fixed fullscreen not applying at startup on Debian (not tested, hope it'll work!)
  - Fixed entity handles not disappearing when movin a resizable entity out of level bounds
  - Fixed a rare crash when saving a project without providing file extension.
  - Fixed various rare minor errors while saving.
  - Fixed "Create group" button in Auto-layer Rules panel
  - Fixed a crash when adding a single entity point
  - Fixed Enum value renaming in Level fields
  - Fixed Enum value renaming in Entity fields
  - Fixed button color in extern enums list
  - Fixed Save or Update operations going super slow while the app wasn't focused
  - Fixed incorrect values listed in the "out-of-bounds policy" select in pure auto-layers rules
  - Fixed email address on contact links
  - Fixed auto-layers baking giving different results if they contained any stacked tiles.
  - Updated various internal libs

# 0.8.1

  - **Fullscreen mode**: just press `F11` to toggle this mode.
  - **New entity tile display modes**: entity tile can now be displayed in more ways: **Repeat** (ie. repeat tile to cover entity bounds), **Cover** (ie. covers the full entity bounds), **Fit Inside** (stretched to fit inside entity bounds).
  - Removed deprecated "Crop" from Entity tile render modes
  - Added an option in LDtk settings to start the app in fullscreen mode
  - Fixed cursor position while zooming
  - Fixed "close" button in Rules panel
  - Fixed scrollbar in Help panel
  - Updated README

# 0.8.0 - Level custom fields, resizable entities and more!

**Note for developers:** *IntGrid layers* JSON format changed in this update. For now, retro-compatibility is maintained with old importers, but this will be dropped after update 0.9.0, breaking outdated importers. Please read all the details here: https://github.com/deepnight/ldtk/issues/358

  - **UI rework**: many interface elements were reworked and cleaned up (less lines, less gutters). This includes panels, main side-bar, custom fields editor, etc. Also, the world panel is now separated from the "current level" panel, so it's no longer mandatory to go to "world view" to edit your active level settings. I hope you'll enjoy the changes :)
  - **Level custom fields**: just like Entities, you can now add custom properties to your levels and edit values per-level. For example, add some FilePath field, name it "music", filter allowed files with "mp3 ogg" and you get a custom music picker in each of your levels.
  - **Custom fields** have been visually re-organized to be easier to read in-editor. Labels and background are now aligned, and various minor display bugs were fixed.
  - **Resizable entities**: Entities can now be marked as resizable horizontally and/or vertically. This new feature opens the possibility of creating "Region" entities (ie. a custom rectangle or ellipses), with fully customizable properties.
  - **Entity tags**: tags are labels that can be freely added to any Entity definition. They can be used to group entities in the editor (ie. actors, regions, interactives etc.) and to filter allowed entities per layers (eg. a "*Region*" layer that can only contain "*region*" tagged entities).
  - **CPU optimizations**: the app CPU usage should now be close to 0% while its window is minimized or not focused. Also, a new setting "Smart CPU throttling" (*enabled* by default, recommended) will also reduce CPU usage while doing "not too demanding" actions in the editor. All these should greatly reduce battery drain on laptops.
  - **Ogmo 3 import**: you can now import Ogmo 3 projects to LDtk. Most features are supported, but feel free to drop a message on GitHub issues if you have any specific needs :)
  - The **UI scaling** has been fixed for 4K and 8K displays. You can now adjust the general application scale factor from the app settings (press `F12`).
  - **CodeMirror**: editing of "multi-lines" fields in entities (and levels) is now done using an almost fullscreen text editor based on *CodeMirror* library. This allows syntax highlighting, basic completion and various quality of life features. Supported types include XML, JSON, Markdown, LUA, JS, C# etc. Feel free to ask for more languages on GitHub issues.
  - **Debug menu**: you can now open a debug menu by pressing `Ctrl+Shift+D`. It will contain some commands that could be useful if you encountered some specific bug types. Commands inside this debug menu are *harmless*, so you can use them *without any risk* (unless some in-app message says the opposite).
  - Tileset can now be changed on-the-fly in each Tile layer.
  - The Windows **setup file** is now twice bigger. Yeah, I know this isn't an actual feature, nor a great change. *But* this opens support for both 32 and 64bits environments. Please note that the *installed* version size hasn't increased, only the *Setup* executable.
  - Moved buttons to the top of project Panels.
  - Removed all "Delete" buttons in project panels
  - It's now possible to associate icons with external enum values from a Haxe HX file.
  - Added a *Preset* button to quickly create a "Region" entity.
  - Entities can now be marked as "Hollow", which will allow editor mouse clicks to pass through, except on edges.
  - You can now show/hide multiple layers at once by holding left mouse button over visibility icons (Photoshop style).
  - Use `Shift` + left click on a visibility icon to Show or hide all other layers except the current one.
  - Added a button to access previous changelogs in "Update" window, on Home screen.
  - An Entity count can now limited per world or per layer. This is especially useful for elements like Player start position, which should be unique in the world.
  - A suggestion to enable Backups will now appear when opening a large project file.
  - The visibility status of a layer is now saved with the project.
  - When baking an Auto-layer (ie. flattening it), you are now given choices on what to do with the original baked auto-layer (delete, empty or keep).
  - Level background is now faded away in "Single layer mode".
  - Smarter auto-naming when duplicating something (ie. a copy of an Entity named "foo50" will now be "foo51", "foo52" etc.)
  - Each Entity field type now has an associated color, making field list easier to read.
  - The default size of a new level can now be customized from the World settings (press `W`, then open settings).
  - **Mouse wheel** can now be used to switch to world mode (and vice versa) automatically. A new related option has been to app settings (`F12`).
  - Fixed zoom speed using mouse wheel.
  - Fixed Point fields in entities where clicking the same coordinate twice added multiple identical points.
  - Fixed Rule "pink" preview being stuck when moving mouse over a level
  - Fixed incorrect default tile when creating a new Enum value.
  - Fixed "New project" dialog opening twice on Home screen
  - Disabled "New level" context menu when holding `Shift` or `Alt`
  - Fixed layer order for "simplified" level render in World view
  - Entity fields are now slightly faded out when not currently on an Entity layer
  - Fixed a "pink square" on Entities when reloading a texture modified outside of LDtk
  - Fixed entity instance editor not closing when switching level
  - Fixed a bug when adding *new Entity fields*, where some existing entity *instances* were not properly updated in the JSON file.
  - Fixed sorting of arrays in entity fields
  - The default behaviour when limiting an entity count is now to "Move the last one" instead "Discard the oldest one".

# 0.7.2

  - Added a setting to change font size in Editor UI.
  - You can now press `F12` to open app settings from almost anywhere.
  - Added a button to delete crash recovery files on Home screen
  - Added file naming customization for layers exported as PNG
  - Fixed selection color (when using `ALT+SHIFT`)
  - More robust JSON parsing with invalid integer numbers
  - Fixed a crash with empty tilesets
  - Fixed a crash loop on Home screen
  - Minor visual fix on splash screen

# 0.7.1

  - Fixed a crash when saving separate level files.
  - Fixed a crash with FilePath fields in Tiled export.
  - Fixed removal of empty dirs when saving a project.
  - Added a new "settings" button to LDtk home screen.
  - Fixed useless autoRuleGroups array in JSON
  - Added an option to force the app to always use the best GPU.

# 0.7.0 - Getting serious

This update features many important changes to make LDtk **production ready** and **future proof**. These changes will allow better support for large projects, better API creation and maintenance, and smoother user adoption.

**We are getting really close to 1.0!**

## Changes

  - **New home layout**: the app home screen has been re-organized to focus on what's really important.
  - **Separate level files**: when enabled, LDtk will save separately the project JSON and one file per level. A much needed feature to reduce JSON size and optimize parsing times! The option is in Project settings (press `F1`): "Separate level files".

    When enabled, all the project **settings** and **definitions** will still be stored in the `*.ldtk` file, and all level data will now be saved to separate files (one per level) in a sub-folder, in `*.ldtkl` files (notice the extra `l` letter at the end of the extension).

    **Important notes**: this new feature might not be supported in all current existing APIs and loaders. Also, this option isn't enabled by default, but this might change on 1.0.
  - **Save layers as PNG**: if you *really* don't want to bother with the LDtk JSON, you can check this new option in your project settings to export all your layers as PNG images (note: only supported layers will be exported, that is those with tiles).
  - **Backups**: automatically keep extra copies of your project in a sub-folder every time you save (enable backups in your project settings). **Important**: LDtk only keeps up to 10 backup files per project.
  - **Crash backups**: if, for some reasons, LDtk crashes, it will try to backup your unsaved work automatically. Obviously, this works even if the backup setting isn't enabled.
  - **Level background image**: each level can now have a custom background image (PNG, GIF or JPEG) that can be resized and aligned in various ways.
  - **New font**: replaced the often hard-to-read pixel font with a sleeker "Roboto" font (this change affects entity fields and floating level informations).
  - **New APIs**: LDtk JSON files can now be easily parsed in many languages, including **C#**, **Python**, **Rust**, **C++**, **Javascript**, using QuickType.io generator. These parsers are based on latest JSON schema file (see below) and are super easy to keep updated. You can check [existing APIs on the LDtk website](https://ldtk.io/api/).
  - **JSON Schema**: a schema file is now directly generated from source code (ie. a JSON that describes the LDtk project file format). It's available on [LDtk.io/json](https://ldtk.io/json) and contains a schema following Draft 7 standard from [Json-schema.org](https://json-schema.org/). This file describes all fields from LDtk json files (value types and descriptions). The great thing about JSON schema is that it allows **JSON "parser" generation** using *QuickType*. That's right: you can now generate Rust, C#, JS or Python parsers easily, right from the file format.
  - **HaxeFlixel support**: the HaxeFlixel game framework has been added to the official [LDtk Haxe API](https://github.com/deepnight/ldtk-haxe-api). You can now easily load and display a LDtk project in your game.
  - Moving your mouse cursor over a **Rule group** in an auto-layer will now reveal all layer cells affected by the rules in this group.
  - If the auto-layer rule panel is open, moving your mouse over the level will now also highlight rules affecting the current coordinate.
  - The [JSON documentation](https://ldtk.io/json) now shows clearly what parts are useful for game devs and what parts aren't (trying to make your dev life even easier!).
  - The app home now shows a **list of recently opened folders** along with recently opened project files.
  - Optimized the rule pattern editor to update less UI stuff when being edited.
  - Tiled TMX files are now exported in a sub folder (along with other optional external files, like levels or layer PNGs)
  - Better organized world panel (shortcut `W`)
  - Better level name display in Linear world layouts.
  - Fixed reloading of tileset images.
  - Fixed Electron related security policy.
  - Fixed "Lost external enum file" dialog when loading a project.
  - Many UI tweaks
  - Bug fixes

# 0.6.2

  - Added an optional **Regular Expression** that can be tested against a `String` field in an Entity. Any unmatched character in a string value will just be discarded. This allows the creation of custom field type (that needs to follow some specific pattern), while still having a safety net (the editor cleans up invalid parts).
  - Fixed missing "world grid size" inputs in Grid Vania layouts. They should now appear in the World panel.
  - Fixed level creation in "Linear" world layouts that only contain 1 level
  - Fixed loading of null multiline fields
  - Fixed a crash on layer removal
  - Added "internal" (ie. "only for editor use") indicator for undocumented fields in Json
  - Fixed Json doc typo
  - Fixed Travis unit tests
  - Fixed new level creation in "Linear" layouts that only contained 1 level
  - Minor changes & fixes on Home and Support pages

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
  - Fixed "new level" spot suggestion in Free and Gridvania worlds.
  - Fixed middle clicks on URL links.
  - Fixed many many issues with rules that didn't update properly after some specific changes (eg. perlin, checker mode, modulos etc.)
  - Added a "locate project" button to Project panel
  - Fixed an infinite loop when resizing a level
  - Fixed corrupted auto-layers when resizing a level using the width/height form fields.
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

# 0.3.1-beta - Tiled import

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

# 0.2.0-beta - Beta version

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

# 0.1.5-alpha - Auto layers

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

# 0.0.1-alpha - First public alpha

 - **Alpha release**: this version is only for early testing & feedback purpose.
 - **Auto updater**: Added support for built-in Electron auto-updater
 - Packaged app with a NSIS setup
 - Added Changelog doc
 - Code: major GIT repo cleaning
