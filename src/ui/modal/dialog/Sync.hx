package ui.modal.dialog;

class Sync extends ui.modal.Dialog {
	public function new(log:SyncLog, filePath:String, newProject:led.Project) {
		super();

		var fileName = dn.FilePath.fromFile(filePath).fileWithExt;
		loadTemplate("sync");
		jContent.find("h2 .file").text( fileName );

		// Warning
		jContent.find(".warning").hide();
		for(l in log)
			switch l.op {
				case Add:
				case ChecksumFix:
				case Remove: jContent.find(".warning").show();
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
				case ChecksumFix: li.append('<span class="op">Updated file checksum</op>');
			}
			li.addClass("op"+Std.string(l.op));
			li.appendTo(jList);
		}

		// Buttons
		addConfirm( function() {
			new LastChance( Lang.t._("External file \"::name::\" synced", { name:fileName }), editor.project );
			editor.selectProject(newProject);
		});

		addCancel();
	}
}