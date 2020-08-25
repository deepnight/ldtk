# About

L-Ed is a **lightweight**, **modern** and **open-source** 2D level editor.

## Features

 - **Easy to use**: modern UI with a strong focus on ease-of-use and quality-of-life features.
 - **Customizable layers**: Integer grid layers, tile layers and entity layers support.
 - **Advanced tileset UI**: you can store on the fly any tile selection from a tileset to reuse it quickly.
 - **Entities**: fully customizable Entity fields (ex: you can have a "Mob" entity, with a "HP" field, which is an Int limited to [0,10] bounds).
 - **Integrated Enums**: you can define an enumeration (ex: an "ItemType" enum with "Money", "Ammo", "Gun" values) and use this enum in your entity custom fields.
 - **Bullet-proof Haxe API**: a powerful Haxe API which gives you access to fully typed values from your levels. It avoids mistakes like mistyping, renaming or removals: you see errors during compilation, not at runtime.
 - **JSON**: easy to parse format for any game-engine out there. Haxe isn't required.

Many new features are planned, but feel free to suggest ideas on the official issue tracker: https://github.com/deepnight/led/issues

## Supported engines "out of the box"

 - **Haxe (any framework)**: https://github.com/deepnight/led-haxe-api
 - More coming soon!

# Install

Get latest version from the official website: https://deepnight.itch.io/l-ed

# How to use

 - Start ``LEd.exe``
 - Create a **NEW LEVEL** from the home page
 - Pick a location for your JSON project file
 - From the editor main screen, click on the **LAYER** button in the top left corner
 - Create a new **INT GRID** layer
 - Close the Layer panel (press ESCAPE or click outside)
 - Start editing :)



## Layer types

### IntGrid layers

These layers are grids of Integer values. Each value has a color and an optional string identifier (for easier access in your code)

### Tile layers

These layers must be linked to an existing Tileset to work.

### Entity layers

These layers host Entity instances, which can be placed along the grid or in free mode.



## Entities

Entities are generic data that can be placed in your levels, such as the Player start position or Items to pick up. Each entity can have various custom editable fields.

These custom fields can be of various types, have limitations and display options.

Various examples:
 - "lifePoints": Integer value within [0,100] bounds, cannot be null
 - "goldDrop": Integer value within [1,∞], can be null, displayed above the entity instance (if not null)

**Important: you need at least one "Entity layer" to place entity instances.**

## Enums

Enumerations (Enums) are special value types for Entities. They could be for example the list of possible Enemy types, or a list of Item identifiers.

Examples:

 - enum "EnemyType" with values: "Zombie", "Skeleton", "Ghost"...
 - enum "ItemType" with values: "Ammo", "HealthPotion", "Key"...

For **Haxe users**, you can even import a HX source file directly to import all (non-parametered) enums declared inside. L-Ed will keep the enums synced and they will even be accessible later in your code through the Haxe API, with all the cool type-safe consequences you can imagine.



# Building from the source

## Requirements

You need an up-to-date and working **Haxe** install (https://haxe.org) to build L-Ed.

Coming soon...

## Compiling

Coming soon...
