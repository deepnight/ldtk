// Source: https://www.npmjs.com/package/codemirror

package codemirror;

@:jsRequire("codemirror")
extern class CodeMirror {
	public static function fromTextArea(e:js.html.TextAreaElement, config:CodeMirrorConfig) : CodeMirror;

	public function getValue(?lineSeparator:String) : String;
	public function setValue(v:String) : Void;
}


typedef CodeMirrorConfig = {
	var ?mode: String;
	var ?theme: String;

	var ?lineNumbers: Bool;
	var ?indentUnit: Int;
	var ?indentWithTabs: Bool;
	var ?tabSize: Int;
}
