package ui.modal.dialog;

// import js.codemirror.*;
import codemirror.CodeMirror;

class TextEditor extends ui.modal.Dialog {
	public function new(str:String, ?mode:ldtk.Json.TextLanguageMode, onChange:String->Void) {
		super("textEditor");

		var jTextArea = new J('<textarea/>');
		jTextArea.appendTo(jContent);
		jTextArea.val(str);

		// Init Codemirror
		var cm = CodeMirror.fromTextArea( cast jTextArea.get(0), {
			mode: requireMode(mode),
			theme: "ayu-mirage",
			lineNumbers: true,
			lineWrapping: true,
		});

		// Load extra addons
		if( mode==LangXml ) {
			js.node.Require.require('codemirror/addon/edit/closetag.js');
			cm.setOption("autoCloseTags", true);
		}
		else {
			js.node.Require.require('codemirror/addon/edit/closebrackets.js');
			cm.setOption("autoCloseBrackets", true);
		}
		// if( mode==LangJson )
		// 	cm.setOption("json", true);

		addClose();
		onCloseCb = ()->onChange( cm.getValue() );
	}

	inline function requireMode(mode:ldtk.Json.TextLanguageMode) : Dynamic {
		// Get mode addon name
		var modeId = switch mode {
			case null: null;
			case LangJson: "javascript";
			case LangXml: "xml";

			case LangHaxe: "haxe";
			case LangJS: "javascript";
			case LangLua: "lua";
			case LangC: "clike";
		}
		if( modeId==null )
			return null;


		// Load language mode
		js.node.Require.require('codemirror/mode/$modeId/$modeId.js');
		var out : Dynamic = {
			name: modeId,
		}

		if( mode==LangJson )
			out.json = true;

		return out;
	}
}