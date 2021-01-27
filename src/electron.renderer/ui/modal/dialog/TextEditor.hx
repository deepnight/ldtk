package ui.modal.dialog;

// import js.codemirror.*;
import codemirror.CodeMirror;

class TextEditor extends ui.modal.Dialog {
	public function new(str:String, ?mode:ldtk.Json.TextLanguageMode, onChange:String->Void) {
		super("textEditor");

		jContent.append('<script src="lib/codemirror.js"></script>');

		var jTextArea = new J('<textarea/>');
		jTextArea.appendTo(jContent);
		jTextArea.val(str);

		var cm = CodeMirror.fromTextArea(cast jTextArea.get(0), {
			mode: switch mode {
				case null: null;
				case LangJson: require("json");
				case LangXml: require("xml");

				case LangHaxe: require("haxe");
				case LangJS: require("javascript");
				case LangLua: require("lua");
				case LangC: require("clike");
			},
			theme: "ayu-mirage",
			lineNumbers: true,
			lineWrapping: true,
			indentWithTabs: true,
		});

		addClose();
		onCloseCb = ()->onChange( cm.getValue() );
	}

	inline function require(mode:String) : String {
		js.node.Require.require('codemirror/mode/$mode/$mode.js');
		return mode;
	}
}