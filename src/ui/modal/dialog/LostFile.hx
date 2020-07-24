package ui.modal.dialog;

class LostFile extends ui.modal.Dialog {
	var onNewPath : String->Void;
	public function new(lostPath:String, onNewPath:(absPath:String)->Void) {
		super("lostFile");

		this.onNewPath = onNewPath;

		var lostName = dn.FilePath.fromFile(lostPath).fileName;
		var lostExt = dn.FilePath.fromFile(lostPath).extension;

		addTitle( Lang.t._("File not found!") );
		addParagraph(Lang.t._("The following file cannot be found anymore:") );

		jContent.append( JsTools.makePath(lostPath) );

		addParagraph(Lang.t._("What do you want to do?") );
		addButton(Lang.t._("Locate the file"), "confirm", function() {
			JsTools.loadDialog(lostExt==null ? null : ["."+lostExt], editor.getProjectDir(), function(newPath:String) {
				newPath = StringTools.replace(newPath, "\\", "/");
				var newName = dn.FilePath.fromFile(newPath).fileName;
				if( newName!=lostName ) {
					// Different naming, that could be suspicious
					new Confirm(
						Lang.t._("The selected file has a different name: are you sure it's the one? Selecting a different file may have dramatic results."),
						pickNewPath.bind(newPath)
					);
				}
				else
					pickNewPath(newPath);
			});
		});

		addButton(Lang.t._("Fix that later"), "cancel", close);
	}

	function pickNewPath(newPath:String) {
		onNewPath(newPath);
		close();
	}
}