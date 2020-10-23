package ui.modal.dialog;

class CrashReport extends ui.modal.Dialog {
	public function new(error:js.lib.Error) {
		super("crash");

		loadTemplate("crash");
		canBeClosedManually = false;
		var jLog = jContent.find(".log");

		try {
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

			// Logging
			App.LOG.error('${error.message} (${error.name})');
			App.LOG.error('${error.stack})');
			App.LOG.flushToFile();

			// Error description
			jLog.append('<li class="desc"> ${error.message} (${error.name})</li>');

			// Copy to clipboard
			jContent.find("button.copy").click( (ev:js.jquery.Event)->{
				var txt = [
					error.message,
					error.name,
					error.stack,
				];
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

			// Stack
			if( niceStack.length==0 ) {
				jLog.html("No extra information available");
			}
			else {
				// var fileNameReg = ~/.*\/(.*\.*.*)/gi;
				for(s in niceStack) {
					var fp = dn.FilePath.fromFile( s.file );
					var jLi = new J('<li class="stack">in: ${s.func}</li>');
					jLi.append('<span class="file">${fp.fileWithExt}</span>');
					jLog.append(jLi);
				}
			}

			// Try to save
			var jBackup = jContent.find(".backup");
			if( editor!=null && !editor.destroyed && editor.needSaving ) {
				var fp = dn.FilePath.fromFile(editor.projectFilePath);
				fp.fileName += Const.CRASH_NAME_SUFFIX;
				var data = JsTools.prepareProjectFile(editor.project);
				JsTools.writeFileBytes(fp.full, data.bytes);
				jBackup.html('I saved your current work in <a>${fp.fileWithExt}</a>.');
				jBackup.find("a").click( (ev)->{
					ev.preventDefault();
					JsTools.exploreToFile(fp.full);
				});
			}
			else
				jBackup.hide();

		}
		catch(e:Dynamic) {
			jLog.append('<li>$e</li>');
			jLog.append('<li>${error.stack}</li>');
		}
	}
}