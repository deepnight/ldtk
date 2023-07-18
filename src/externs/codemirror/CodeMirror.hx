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

@:jsRequire("codemirror")
extern class CodeMirror {
	public static function fromTextArea(e:js.html.TextAreaElement, config:CodeMirrorConfig):CodeMirror;

	public function getValue(?lineSeparator:String):String;
	public function setValue(v:String):Void;
	public function setOption(name:String, val:Dynamic):Void;
	public function on(eventName:String, cb:(args:Dynamic) -> Void):Void;

	/**
		Possible values: selectAll, goDocStart/End, goLineStart/End ...
		https://codemirror.net/doc/manual.html#commands
	**/
	public function execCommand(name:ExecCommand):Void;

	public static function autoShowComplete(cm:Dynamic, event:Dynamic):Void;
}

typedef CodeMirrorConfig = {
	var ?mode:haxe.extern.EitherType<String, {}>; // string or object
	var ?theme:String;

	var ?lineWrapping:Bool;
	var ?lineNumbers:Bool;
	var ?indentUnit:Int;
	var ?indentWithTabs:Bool;
	var ?tabSize:Int;
	var ?autofocus:Bool;
	var ?extraKeys:Dynamic;

	/** True, false or "nocursor" **/
	var ?readOnly:haxe.extern.EitherType<Bool, String>;
}
