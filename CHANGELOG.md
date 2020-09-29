# LEd release notes

## 0.2.2-beta
 - **Group of tiles in auto-layer rules**: this new feature allows you to place larger objects (eg. *a tree, a big rock, etc.*) made of multiple tiles using just auto-layer rules.
 - Added **Modulo** options for auto-layer rules: this allows a rule to only apply every X columns or Y rows.
 - Added **Checker mode** for auto-layer rules: this makes effects like "brick walls" or "Sonic checker effect" possible ;)
 - Fixed image import that failed if the image file was standing on a different drive than the project file.
 - Fixed rule `random` function giving identical results for different rules
 - Fixed a crash while editing rules in *pure* auto-layers.
 - Fixed a crash when Undo history reaches its max.
 - Updated `Samples`
 - Bug fixes


## 0.2.1-beta

 - Added `F1`-`F6` key shortcuts for all editor panels
 - Updated JSON file format with some extra dev-friendly values
 - Added a JSON changelog file for devs working on importers
 - Add JSON changelog to app start page

## 0.2.0-beta

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

## 0.1.7-alpha

 - **Array of entity fields**: any field type in an Entity can now be an Array. For example, you could have an Array of Enums to represent the items hidden inside a Cratebox entity. See `Samples` for some examples.
 - **Point coordinates & paths**: this new entity field type allows you to pick a grid coordinates. And if you combine this with the new Array support, you can even build paths of points! See `Samples` for some examples.
 - Added a confirmation when trying to update the app while having unsaved changes
 - UI tweaks & fixes
 - Added some click tolerance when picking entities
 - Swapped "Tileset" and "Enum" buttons in main toolbar
 - Fixed an infinite loop on undo/redo in some levels
 - Updated Haxe API
 - Bug fixes

## 0.1.6-alpha

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

## 0.1.5-alpha

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

## 0.0.4-alpha

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

## 0.0.3-alpha

 - Better **Entity instance fields editor**
 - Better **auto-update UI**
 - Enhanced ALT-click picking cursor
 - Fixed Changelog display on Home page
 - ALT+click picking no longer picks in other layers by default (you can hold `SHIFT` key to pick in any layer)
 - Fixed window closing not working sometimes
 - Added a brief notification when switching layers using picking
 - Code: Electron cleanup

## 0.0.2-alpha

 - **Release notes**: added release notes to app Home page
 - Adjusted grid opacity
 - Bug fixes
 - Dev scripts cleanup

## 0.0.1-alpha

 - **Alpha release**: this version is only for early testing & feedback purpose.
 - **Auto updater**: Added support for built-in Electron auto-updater
 - Packaged app with a NSIS setup
 - Added Changelog doc
 - Code: major GIT repo cleaning
