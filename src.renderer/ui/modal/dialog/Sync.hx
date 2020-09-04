package ui.modal.dialog;

class Sync extends ui.modal.Dialog {
	public function new(log:SyncLog, filePath:String, newProject:led.Project) {
		super();

		var fileName = dn.FilePath.fromFile(filePath).fileWithExt;
		loadTemplate("sync");
		jContent.find("h2 .file").text( fileName );

		// Add "DateUpdated" line
		log = log.copy();
		log.push({ op:DateUpdated, str:'$fileName date' });

		// Warning
		jContent.find(".warning").hide();
		for(l in log)
			switch l.op {
				case Add:
				case ChecksumUpdated:
				case DateUpdated:
				case Remove(used): if( used ) jContent.find(".warning").show();
			}

		// Hide safe notice
		if( jContent.find(".warning").is(":visible") )
			jContent.find(".safe").hide();

		// Log
		var jList = jContent.find(".log");
		jList.appendTo(jContent);
		for(l in log) {
			var li = new J('<li></li>');
			li.append(l.str);
			switch l.op {
				case Add: li.append('<span class="op">New</op>');

				case Remove(used):
					li.append('<span class="op">${ used ? "Removed (USED IN PROJECT)" : "Removed (but not actually used in project)" }</op>');
					if( !used )
						li.addClass("unused");

				case ChecksumUpdated:
					li.append('<span class="op">No change</op>');

				case DateUpdated:
					li.append('<span class="op">updated</op>');
			}
			li.addClass("op"+l.op.getName());
			li.appendTo(jList);
		}

		// Buttons
		addButton("Apply these changes", "confirm", function() {
			new LastChance( Lang.t._("External file \"::name::\" synced", { name:fileName }), editor.project );
			editor.selectProject(newProject);
		});

		addCancel();
	}
}