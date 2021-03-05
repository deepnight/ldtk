package ui.modal.dialog;

class ExternalFileChanged extends ui.modal.Dialog {
	public function new(filePath:String, onFix:Void->Void) {
		super("fileChanged");

		addTitle( Lang.t._("File was modified"), true );
		addParagraph(Lang.t._("The following file has been modified externally and should be updated:") );

		jContent.append( JsTools.makePath(filePath) );

		addParagraph(Lang.t._("What do you want to do?") );
		addButton(Lang.t._("Reload it"), "confirm", function() {
			onFix();
			close();
		});
		addButton(Lang.t._("Fix that later"), "cancel", close);
	}
}