package ui.modal.dialog;

class EnumImport extends ui.modal.Dialog {
	public function new(log:Array<String>, filePath:String, newProject:led.Project) {
		super();

		loadTemplate("enumImport");
		jContent.find("h2 .file").text( dn.FilePath.fromFile(filePath).fileWithExt );

		var jList = jContent.find(".log");
		jList.appendTo(jContent);
		for(str in log) {
			var li = new J('<li>$str</li>');
			if( str.toLowerCase().indexOf("added")>=0 )
				li.addClass("good");
			else if( str.toLowerCase().indexOf("removed")>=0 )
				li.addClass("bad");
			li.appendTo(jList);
		}

		addConfirm( function() {
			new LastChance( Lang.t._("External enums synced"), editor.project );
			editor.selectProject(newProject);
		});

		addCancel();
	}
}