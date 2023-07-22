// Source: https://www.npmjs.com/package/codemirror
package codemirror;

import js.lib.Object;

@:enum
abstract ExecCommand(String) {
	var GoLineStart = "goLineStart";
	var GoLineEnd = "goLineEnd";
	var GoDocStart = "goDocStart";
	var GoDocEnd = "goDocEnd";
}

// @:jsRequire("codemirror")
// extern class CodeMirror {
// 	public static function fromTextArea(e:js.html.TextAreaElement, config:CodeMirrorConfig):CodeMirror;
// 	public function getValue(?lineSeparator:String):String;
// 	public function setValue(v:String):Void;
// 	public function setOption(name:String, val:Dynamic):Void;
// 	public function on(eventName:String, cb:(args:Dynamic) -> Void):Void;
// 	/**
// 		Possible values: selectAll, goDocStart/End, goLineStart/End ...
// 		https://codemirror.net/doc/manual.html#commands
// 	**/
// 	public function execCommand(name:ExecCommand):Void;
// 	public static function autoShowComplete(cm:Dynamic, event:Dynamic):Void;
// }

@:jsRequire("codemirror", "EditorView")
extern class EditorView {
	function new(options:Dynamic);

	var dom:Dynamic;
	var state:Dynamic;
}

var basicSetup = Reflect.field(js.Lib.require("codemirror"), "basicSetup");
var python = Reflect.field(js.Lib.require("@codemirror/lang-python"), "python");
var indentWithTab = Reflect.field(js.Lib.require("@codemirror/commands"), "indentWithTab");
var keymap = Reflect.field(js.Lib.require("@codemirror/view"), "keymap");
var oneDark = Reflect.field(js.Lib.require("@codemirror/theme-one-dark"), "oneDark");

// extern dynamic basicSetup;
// @jsrequire("@codemirror/view", "EditorState")
// @jsrequire("codemirror")
// extern class EditorState {
// 	function new(options:Dynamic);
// 	public function create(?state:Dynamic):Dynamic;
// }
// typedef CodeMirrorConfig = {
// 	var ?mode:haxe.extern.EitherType<String, {}>; // string or object
// 	var ?theme:String;
// 	var ?lineWrapping:Bool;
// 	var ?lineNumbers:Bool;
// 	var ?indentUnit:Int;
// 	var ?indentWithTabs:Bool;
// 	var ?tabSize:Int;
// 	var ?autofocus:Bool;
// 	var ?extraKeys:Dynamic;
// 	/** True, false or "nocursor" **/
// 	var ?readOnly:haxe.extern.EitherType<Bool, String>;
// }
