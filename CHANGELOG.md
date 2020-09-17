# LEd release notes

## 0.1.6-alpha

 - **"Pure" auto-layers**: these layers only have rules and use a separate IntGrid layer as source for their value checks. Very useful to have a separate auto-layer that contains drop-shadows of walls, for example. You can have any number of pure auto-layers using the same single IntGrid source.

## 0.1.5-alpha

 - **Auto-layers**: IntGrid layers can now render themselves automatically by drawing tiles based on their content. You can create "patterns of IntGrid values" (called **Rules**) to decide when a specific tile, or group of random tiles, should appear. It can for example be used to:
   - add random grass or rocks on top of platforms,
   - add random ceiling props under platforms,
   - render ground/water/lava area,
   - etc.
 - Auto-layer rules can be organized in groups.
 - **Samples**: click on the *Samples* button on home page to load some example projects.
 - **Smarter warning** when deleting something in a panel. ie. If the value you're removing isn't actually used in your project, you will get a "softer" warning.
 - **Large levels optimizations**: started an important rework of the way levels are rendered on-screen to make room for future optimizations on large levels. For now, it's still recommended to work on levels with smaller dimensions.
 - Added a project option to minify the JSON file.
 - Smarter extern Enum sync: the removal of unused enums will be shown as low-risks operations.
 - Added perlin noise support to Auto-layers rules (a rule can apply to only a random area).
 - Changed version number to 0.1.x because no one could stop me from doing it
 - Better element sorting (levels, layers etc.) experience using SortableJS lib
 - Closing a panel with a color picker will now validate color before closing the panel.
 - Better viewport centering when opening a level.
 - Fixed 0-9 keyboard shortcuts while focusing a field
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
 - Fixed **CTRL-W** shortcut (should only close current app page)
 - Added **CTRL-Q** shortcut to close the app
 - Added **F** shortcut to fit current level in screen
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
 - ALT+click picking no longer picks in other layers by default (you can hold SHIFT key to pick in any layer)
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
