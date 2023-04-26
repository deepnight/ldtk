package ui.modal.dialog;
import dn.Col;

class CommandRunner extends ui.modal.Dialog {
	var jOutput : js.jquery.JQuery;
	var onComplete : Null< Void->Void >;

	private function new(p:data.Project, cmd:ldtk.Json.CustomCommand, ?onComplete:Void->Void) {
		super();
		loadTemplate("commandRunner");
		canBeClosedManually = false;
		this.onComplete = onComplete;

		jOutput = jContent.find(".output");


		var jClose = jContent.find(".close");
		jClose.click( _->close() );
		var jKill = jContent.find(".kill");

		if( !settings.isProjectTrusted(p.iid) ) {
			// Trust warning
			jContent.addClass("untrusted");
			var jWarn = jContent.find(".untrustedWarning");
			jWarn.find(".commands.current").text(cmd.command);
			if( p.customCommands.length<=1 )
				jWarn.find(".others").hide();
			else {
				for(other in p.customCommands)
					if( other!=cmd )
						jWarn.find(".others .commands").append(other.command+"\n");
			}

			jWarn.find(".allow").click(_->{
				settings.setProjectTrust(p.iid, true);
				jContent.removeClass("untrusted");
				runCommand(p, cmd);
			});
			jWarn.find(".block").click(_->{
				settings.setProjectTrust(p.iid, false);
				close();
			});
			jWarn.find(".cancel").click(_->{
				close();
			});
		}
		else if( cmd.command!="" ) {
			runCommand(p, cmd);
		}
		else {
			// No command
			close();
		}
	}

	function runCommand(p:data.Project, cmd:ldtk.Json.CustomCommand) {
		var needManualClosing = false;

		var jKill = jContent.find(".kill");
		var jClose = jContent.find(".close");

		var args = parseCommandToArray(cmd.command);

		var name = args.shift();

		if( name==null || name.length==0 ) {
			jKill.prop("disabled", true);
			return;
		}

		jClose.prop("disabled", true);

		// Create child process
		print("Executing: " + cmd.command, White);
		separator();

		var proc = js.node.ChildProcess.spawn(name, args, {cwd: p.getProjectDir()});
		proc.stdout.on("data", out->print(out));
		proc.stderr.on("data", out->print(out, 0xffcc00));
		proc.on("error", e->print(e, 0xff5555));
		proc.on("close", (code:Null<Int>)->{
			separator();
			jKill.prop("disabled", true);
			jClose.prop("disabled", false);
			if( code==null )
				print("Terminated", White);
			else
				print("Terminated with code "+code, White);

			N.msg("Command executed: "+cmd.command.substr(0, 20) + (cmd.command.length>20 ? "..." : ""));

			if( !needManualClosing && ( code==null || code==0 ) )
				close();
		});

		// Kill button
		jKill.click(_->{
			print("Sent kill signal!", 0xff5555);
			needManualClosing = true;
			proc.kill();
		});
	}

	private static function parseCommandToArray(argString:String) {
		var args = new Array<String>();

		var inQuotes = false;
		var escaped = false;
		var lastCharWasSpace = true;
		var arg = '';

		for (i in 0...argString.length) {
			var c = argString.charAt(i);

			if (c == ' ' && !inQuotes) {
				if (!lastCharWasSpace) {
					args.push(arg);
					arg = '';
				}
				lastCharWasSpace = true;
				continue;
			} else {
				lastCharWasSpace = false;
			}

			if (c == '"') {
				if (!escaped) {
					inQuotes = !inQuotes;
				} else {
					if (escaped && c != '"') {
						arg += '\\';
					}

					arg += c;
					escaped = false;
				}
				continue;
			}

			if (c == "\\" && escaped) {
				if (escaped && c != '"') {
					arg += '\\';
				}

				arg += c;
				escaped = false;
				continue;
			}

			if (c == "\\" && inQuotes) {
				escaped = true;
				continue;
			}

			if (escaped && c != '"') {
				arg += '\\';
			}

			arg += c;
			escaped = false;

			lastCharWasSpace = false;
		}

		if (!lastCharWasSpace) {
			args.push(StringTools.trim(arg));
		}

		return args;
	}

	public static function runSingleCommand(p:data.Project, cmd:ldtk.Json.CustomCommand, ?onComplete:Void->Void) {
		if( App.ME.settings.isProjectUntrusted(p.iid) ) {
			if( onComplete!=null )
				onComplete();
			return;
		}

		new CommandRunner(p, cmd, onComplete);
	}

	public static function runMultipleCommands(p:data.Project, cmds:Array<ldtk.Json.CustomCommand>, onComplete:Void->Void) {
		if( App.ME.settings.isProjectUntrusted(p.iid) ) {
			if( onComplete!=null )
				onComplete();
			return;
		}

		if( cmds.length>0 ) {
			var idx = 0;
			function _run(cmd:ldtk.Json.CustomCommand) {
				new ui.modal.dialog.CommandRunner(p, cmd, ()->{
					idx++;
					if( idx<cmds.length )
						_run(cmds[idx]);
					else
						onComplete();
				});
			}
			_run(cmds[0]);
		}
		else
			onComplete();
	}


	override function onClose() {
		super.onClose();
		if( onComplete!=null )
			onComplete();
	}

	override function onClickMask() {
		super.onClickMask();
		jContent.find(".close:not(:disabled)").click();
	}

	function print(v:Dynamic, ?col:dn.Col) {
		var str = StringTools.htmlEscape( Std.string(v) );
		var jPre = new J('<pre>$str</pre>');
		if( col!=null )
			jPre.css({ color: col.toHex() });
		jOutput.append(jPre);
	}
	function separator() {
		var jPre = new J('<pre class="sep"></pre>');
		jOutput.append(jPre);
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( keyCode==K.ESCAPE )
			jContent.find(".close:not(:disabled)").click();
	}
}