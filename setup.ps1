param(
    [Parameter(Mandatory=$true)]
    [String]$ldtkHaxeApiBranch
)

haxe .\setup.hxml

haxelib git ldtk-haxe-api https://github.com/deepnight/ldtk-haxe-api.git $ldtkHaxeApiBranch --always
haxelib git deepnightLibs https://github.com/deepnight/deepnightLibs master --always

cd app
npm i
cd ..

npm i -g sass

haxe main.debug.hxml
haxe renderer.debug.hxml
