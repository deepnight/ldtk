package page;

import hxd.Key;

class CrashReport extends Page {
	public function new(error:js.lib.Error, activeProcesses:String, ?unsavedProject:data.Project, ?projectFilePath:String) {
		super();

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
			App.LOG.error('${error.stack})');
			App.LOG.emptyEntry();
			App.LOG.general("\n"+dn.Process.rprintAll());
			App.LOG.emptyEntry();
			App.LOG.flushToFile();

			// Parse stack
			var stackReg = ~/ at (.*?) \((.*?):([0-9]+):([0-9]+)\)/gim;
			var raw = error.stack;
			var niceStack = [];
			while( raw!=null && stackReg.match(raw) ) {
				niceStack.push({
					func: stackReg.matched(1),
					file: stackReg.matched(2),
					col: Std.parseInt( stackReg.matched(3) ),
				});
				raw = stackReg.matchedRight();
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
				var fp = dn.FilePath.fromFile(projectFilePath);
				fp.fileName += Const.CRASH_NAME_SUFFIX;
				var data = JsTools.prepareProjectSavingData(unsavedProject);
				// BUG support multifiles!
				JsTools.writeFileString(fp.full, data.projectJson);
				jBackup.html('I saved your current work in <a>${fp.fileWithExt}</a>.');
				jBackup.find("a").click( (ev)->{
					ev.preventDefault();
					JsTools.exploreToFile(fp.full, true);
				});
			}
			else
				jBackup.hide();

		}
		catch(e:Dynamic) {
			jError.html( "Double error: "+Std.string(e) + "\n" + error.stack  );
		}
	}
}
