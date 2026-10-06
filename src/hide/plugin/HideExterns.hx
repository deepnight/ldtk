package hide.plugin;

@:native("hide.Ide")
extern class Ide {
	static var inst(default, never):Ide;
	var database(default, never):Dynamic; // cdb.Database
	var databaseFile(default, never):String; // private in Haxe, plain field in JS
	var config(default, never):Dynamic; // { current: hide.Config, ... }
	function getPath(relPath:String):String;
}

@:native("hide.ui.View")
extern class View {
	function new(state:Dynamic);
	var element:Dynamic; // jquery
	function getTitle():String;
	function onDisplay():Void;
	function onBeforeClose():Bool;
	function destroy():Void;
	static function register(cl:Class<Dynamic>, ?options:Dynamic):Dynamic;
}
