// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;

// @:enum
// abstract ExecCommand(String) {
// 	var GoLineStart = "goLineStart";
// 	var GoLineEnd = "goLineEnd";
// 	var GoDocStart = "goDocStart";
// 	var GoDocEnd = "goDocEnd";
// }

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:String, options:Dynamic);

	public function on(eventName:String, cb:(args:Dynamic)->Void) : Void;

	// public static function fromTextArea(e:js.html.TextAreaElement, config:CodeMirrorConfig) : CodeMirror;

	// public function getValue(?lineSeparator:String) : String;
	// public function setValue(v:String) : Void;
	// public function setOption(name:String, val:Dynamic) : Void;

	// /**
	// 	Possible values: selectAll, goDocStart/End, goLineStart/End ...
	// 	https://codemirror.net/doc/manual.html#commands
	// **/
	// public function execCommand(name:ExecCommand) : Void;
}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue() : Dynamic;
	public function getOldValue() : Dynamic;
	public function getRow() : Dynamic;
	public function getColumn() : Dynamic;
	public function getField() : Dynamic;
}

@:jsRequire("tabulator-tables")
extern class RowComponent {
	public function getValue() : Dynamic;
}


// typedef CodeMirrorConfig = {
// 	var ?mode: haxe.extern.EitherType<String,{}>; // string or object
// 	var ?theme: String;

// 	var ?lineWrapping: Bool;
// 	var ?lineNumbers: Bool;
// 	var ?indentUnit: Int;
// 	var ?indentWithTabs: Bool;
// 	var ?tabSize: Int;
// 	var ?autofocus: Bool;

// 	/** True, false or "nocursor" **/
// 	var ?readOnly: haxe.extern.EitherType<Bool,String>;
// }
