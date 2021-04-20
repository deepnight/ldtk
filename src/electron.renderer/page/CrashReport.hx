package page;

import hxd.Key;

class CrashReport extends Page {
	public function new(error:js.lib.Error, activeProcesses:String, ?unsavedProject:data.Project, ?projectFilePath:String) {
		super();

		App.LOG.flushToFile();

		dn.Process.destroyAllExcept([this, App.ME]);
		App.ME.delayer.cancelEverything();
		App.ME.removeMask();

		if( Editor.ME!=null )
			Editor.ME.destroy();

		// Init
		loadPageTemplate("crashReport", {
			app: Const.APP_NAME,
		});
		App.ME.setWindowTitle();

		var jContent = jPage.find(".wrapper");
		var jError = jContent.find(".error");
		try {
			// Logging
			App.LOG.error('${error.message} (${error.name})');
			App.LOG.error('${error.stack}');
			App.LOG.emptyEntry();
			App.LOG.general("\n"+dn.Process.rprintAll());
			App.LOG.emptyEntry();
			App.LOG.flushToFile();

			// Parse stack
			if( error.stack!=null ) {
				var stackReg = ~/ at (.*?) \((.*?):([0-9]+):([0-9]+)\)/gim;
				var raw = error.stack;
				var niceStack = [];
				while( stackReg.match(raw) ) {
					niceStack.push({
						func: stackReg.matched(1),
						file: stackReg.matched(2),
						col: Std.parseInt( stackReg.matched(3) ),
					});
					raw = stackReg.matchedRight();
				}
			}

			// Error description
			jError.html('${error.message} (${error.name})');

			// Copy to clipboard
			jContent.find("button.copy").click( (ev:js.jquery.Event)->{
				var txt = [
					"",
					"Stack:",
					"```",
					"LDtk version: "+Const.getAppVersion(),
					error.message,
					error.name,
					error.stack,
					"```",
					"Processes:",
					"```",
					activeProcesses,
					"```",
					"",
					"Log:",
					"```",
				];
				txt = txt.concat( App.LOG.getLasts(50) );
				txt.push("```");
				electron.Clipboard.write({ text:txt.join("\n") });
				ev.getThis()
					.addClass("done")
					.text("Copied to clipboard!");
			});

			// Report
			jContent.find("button.report").click( (_)->{
				electron.Shell.openExternal( Const.ISSUES_URL );
			});

			// Restart
			jContent.find("button.restart").click( (_)->{
				js.Browser.window.location.reload();
			});

			// Try to save
			var jBackup = jContent.find(".backup");
			if( unsavedProject!=null ) {
				try {
					// Build file name & path
					var fp = ui.ProjectSaving.makeBackupFilePath(unsavedProject, "crash");

					// Init dirs
					if( !NT.fileExists(fp.directory) )
						NT.createDirs(fp.directory);

					// Save
					var data = ui.ProjectSaving.prepareProjectSavingData(unsavedProject, true);
					NT.writeFileString(fp.full, data.projectJson);
					jBackup.html("But don't worry, your work was saved in a backup file! ");

					// Register in recents
					App.ME.registerRecentProject(fp.full);
				}
				catch(err:Dynamic) {
					jBackup.html("I tried to save your current work in a backup file, but it failed (ERR: "+err+")");
				}
			}
			else
				jBackup.hide();

		}
		catch(e:Dynamic) {
			jError.html( "Double error: "+Std.string(e) + "\n" + error.stack  );
		}
	}
}
