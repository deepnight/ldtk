package ui.modal.dialog;

class LostFile extends ui.modal.Dialog {
	var onNewPath : String->Void;
	public function new(lostPath:String, onNewPath:(absPath:String)->Void) {
		super("lostFile");

		App.LOG.error("Lost file: "+lostPath);

		this.onNewPath = onNewPath;

		var fp = dn.FilePath.fromFile(lostPath);
		var lostName = fp.fileName;
		var lostExt = fp.extension;

		addTitle( Lang.t._("File not found!"), true );
		addParagraph(Lang.t._("The following file cannot be found anymore:") );

		jContent.append( JsTools.makePath(lostPath) );

		addParagraph(Lang.t._("What do you want to do?") );
		addButton(Lang.t._("Locate the file"), "confirm", function() {
			var lostFullPath = project.makeAbsoluteFilePath( fp.full );
			var lostDir = dn.FilePath.extractDirectoryWithoutSlash(lostFullPath, true);
			var baseDir = NT.fileExists(lostDir) ? lostDir : project.getProjectDir();

			dn.js.ElectronDialogs.openFile(lostExt==null ? null : ["."+lostExt], baseDir, function(newPath:String) {
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

		addButton(Lang.t._("Fix that later"), "cancel", ()->{
			App.LOG.general("Relocation canceled");
			close();
		});
	}

	function pickNewPath(newPath:String) {
		new LastChance( Lang.t._("Relocated a lost file"), editor.project );
		App.LOG.fileOp("Relocated lost file: "+newPath);
		onNewPath(newPath);
		close();
	}
}