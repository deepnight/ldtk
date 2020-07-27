package ui.modal.dialog;

class EnumImport extends ui.modal.Dialog {
	public function new(log:SyncLog, filePath:String, newProject:led.Project) {
		super();

		loadTemplate("enumImport");
		jContent.find("h2 .file").text( dn.FilePath.fromFile(filePath).fileWithExt );

		// Warning
		jContent.find(".warning").hide();
		for(l in log)
			switch l.op {
				case Add:
				case Remove:
					jContent.find(".warning").show();
			}

		// Log
		var jList = jContent.find(".log");
		jList.appendTo(jContent);
		for(l in log) {
			var li = new J('<li></li>');
			li.append(l.str);
			switch l.op {
				case Add: li.append('<span class="op">New</op>');
				case Remove: li.append('<span class="op">Removed</op>');
			}
			li.addClass("op"+Std.string(l.op));
			li.appendTo(jList);
		}

		// Buttons
		addConfirm( function() {
			new LastChance( Lang.t._("External enums synced"), editor.project );
			editor.selectProject(newProject);
		});

		addCancel();
	}
}