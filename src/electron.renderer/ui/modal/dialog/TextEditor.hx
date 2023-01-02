package ui.modal.dialog;

// import js.codemirror.*;
import codemirror.CodeMirror;

class TextEditor extends ui.modal.Dialog {
	public var jHeader : js.jquery.JQuery;
	public var jTextArea : js.jquery.JQuery;
	var cm: CodeMirror;

	public function new(str:String, title:String, ?desc:String, ?mode:ldtk.Json.TextLanguageMode, ?onChange:(str:String)->Void, ?onNoChange:Void->Void) {
		super("textEditor");

		var anyChange = false;
		var readOnly = onChange==null;

		new J('<h2>$title</h2>').appendTo(jContent);

		jHeader = new J('<div class="header"/>');
		jHeader.appendTo(jContent);

		if( desc!=null ) {
			var parags = "<p>" + desc.split("\\n").join("</p><p>") + "</p>";
			new J('<div class="help">$parags</div>').appendTo(jHeader);
		}

		jTextArea = new J('<textarea/>');
		jTextArea.appendTo(jContent);
		jTextArea.val(str);

		// Init Codemirror
		cm = CodeMirror.fromTextArea( cast jTextArea.get(0), {
			mode: requireMode(mode),
			theme: "lucario",
			lineNumbers: true,
			lineWrapping: true,
			readOnly: readOnly,
			autofocus: true,
		});
		cm.on("change", (ev)->anyChange=true );

		// Load extra addons
		if( mode==LangXml ) {
			js.node.Require.require('codemirror/addon/edit/closetag.js');
			cm.setOption("autoCloseTags", true);
		}
		else {
			js.node.Require.require('codemirror/addon/edit/closebrackets.js');
			cm.setOption("autoCloseBrackets", true);
		}

		onCloseCb = ()->{
			 var out = cm.getValue();
			 if( anyChange && str!=out ) {
				if( onChange!=null )
					onChange(out);
			 }
			 else if( onNoChange!=null )
				onNoChange();
		}

		addClose();

		if( !readOnly )
			addIconButton("delete", "red small delete", ()->{
				cm.setValue("");
				close();
			} );
	}

	public function scrollToEnd() {
		cm.execCommand(GoDocEnd);
	}

	inline function requireMode(mode:ldtk.Json.TextLanguageMode) : Dynamic {
		// Get mode addon name
		var modeId = switch mode {
			case null: null;
			case LangJson: "javascript";
			case LangXml: "xml";
			case LangMarkdown: "markdown";

			case LangRuby: "ruby";
			case LangPython: "python";
			case LangHaxe: "haxe";
			case LangJS: "javascript";
			case LangLua: "lua";
			case LangC: "clike";

			case LangLog: "ttcn-cfg";
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


	/** Open an external text file and edit it **/
	public static function editExternalFile(filePath:String) {
		var fp = dn.FilePath.fromFile(filePath);
		if( !NT.fileExists(fp.full) ) {
			N.error(L.t._("File not found."));
			return false;
		}

		// Read file
		var bytes = NT.readFileBytes(fp.full);
		if( bytes==null ) {
			N.error(L.t._("Could not read file content."));
			return false;
		}

		// Check if file can be edited in plain text
		switch dn.Identify.getType(bytes) {
			case Unknown:
			case Aseprite, Png, Jpeg, Gif, Bmp:
				N.error("You cannot edit an image here.");
				return false;
		}
		var raw = bytes.toString();

		var c = "";
		for(i in 0...M.imin(256, bytes.length)) {
			c = bytes.getString(i,1);
			if( c==null || c.length==0 || c.charCodeAt(0) > 127 ) {
				N.error(L.t._("Hey, it looks like a binary file: this cannot be opened in this editor."));
				return false;
			}
		}


		// Guess display language
		var mode : ldtk.Json.TextLanguageMode = null;
		if( fp.extension!=null )
			mode = switch fp.extension.toLowerCase() {
				case "txt", "cfg": null;
				case "xml", "html", "xhtml", "jhtml", "tpl", "rss", "svg": LangXml;
				case "js": LangJS;
				case "hx", "hscript": LangHaxe;
				case "py": LangPython;
				case "rb","rhtml": LangRuby;
				case "lua": LangLua;
				case "md": LangMarkdown;
				case "json", Const.FILE_EXTENSION, Const.LEVEL_EXTENSION: LangJson;
				case "cs", "csx", "c", "cpp", "c++", "cp", "cc", "h": LangC;
				case _: LangJS;
			}

		// Open editor
		var editor = new TextEditor(
			raw,
			fp.fileWithExt,
			mode,
			(str)->{
				NT.writeFileString(fp.full, str);
				N.success( L.t._('File "::name::" saved.', { name:fp.fileWithExt }) );
			}
		);
		return true;
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		switch keyCode {
			case K.ESCAPE: close();
			case _:
		}
	}
}