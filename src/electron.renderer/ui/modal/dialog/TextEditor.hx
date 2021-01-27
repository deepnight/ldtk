package ui.modal.dialog;

// import js.codemirror.*;
import codemirror.CodeMirror;

class TextEditor extends ui.modal.Dialog {
	public function new(str:String, onChange:String->Void) {
		super("textEditor");

		jContent.append('<script src="lib/codemirror.js"></script>');

		var jTextArea = new J('<textarea/>');
		jTextArea.appendTo(jContent);
		jTextArea.val(str);

		var cm = CodeMirror.fromTextArea(cast jTextArea.get(0), {
			mode: "javascript",
			theme: "ayu-mirage",
			lineNumbers: true,
			indentWithTabs: true,
		});

		addClose();
		onCloseCb = ()->onChange( cm.getValue() );
	}
}