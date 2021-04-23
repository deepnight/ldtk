`{`
 - `"__header__"` `{` ... `}` *-- File header*
 - [Global project properties](#ldtk-ProjectJson)

 - `"defs" : {`
    - `"layers" : [ ` [&lt;Layer definitions&gt;]() `],`
    - `"entities" : [ ` [&lt;Entity definitions&gt;]() with [&lt;Field definitions&gt;]() `],`
    - `"tilesets" : [ ` [&lt;Tileset definitions&gt;]() `],`
    - `"enums" : [ ` [&lt;Enum definitions&gt;]() `],`
    - `"externalEnums" : [ ` [&lt;Enum definitions&gt;]() `],`
    - `"levelFields" : [ ` [&lt;Field definitions&gt;]() `]`
  - `}`

  - `"levels" : [`
    - `{`
      - [&lt;Level properties&gt;]()
	  - `"layers" : [ ` [&lt;Layer instances&gt;]() `]`
    - `},`
    - ...
  - `]`

`}`
