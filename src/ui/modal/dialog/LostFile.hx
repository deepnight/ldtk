package ui.modal.dialog;

class LostFile extends ui.modal.Dialog {
	public function new(lostPath:String, onNewPath:(absPath:String)->Void) {
		super("lostFile");

		addTitle( Lang.t._("File not found!") );
		addParagraph(Lang.t._("The following file cannot be found anymore:") );

		jContent.append( JsTools.makePath(lostPath) );

		addParagraph(Lang.t._("What do you want to do?") );
		addButton(Lang.t._("Locate the file"), "confirm", function() {
			var ext = dn.FilePath.fromFile(lostPath).extension;
			JsTools.loadDialog(ext==null ? null : ["."+ext], editor.getProjectDir(), function(newPath:String) {
				onNewPath(newPath);
				close();
			});
		});

		addButton(Lang.t._("Fix that later"), "cancel", close);
	}
}