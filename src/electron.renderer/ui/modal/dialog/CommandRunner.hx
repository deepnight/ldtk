package ui.modal.dialog;
import dn.Col;

class CommandRunner extends ui.modal.Dialog {
	var jOutput : js.jquery.JQuery;
	var onComplete : Null< Void->Void >;

	public function new(p:data.Project, cmd:ldtk.Json.CustomCommand, ?onComplete:Void->Void) {
		super();
		loadTemplate("commandRunner");
		canBeClosedManually = false;
		this.onComplete = onComplete;

		jOutput = jContent.find(".output");
		var jClose = jContent.find(".close");
		jClose.click(_->{
			close();
		});

		var jKill = jContent.find(".kill");
		var needManualClosing = false;

		if( cmd.command!="" ) {
			// Run command
			jClose.prop("disabled", true);
			var splitIdx = cmd.command.indexOf(" ");
			var name = splitIdx<0 ? cmd.command : cmd.command.substr(0,splitIdx);
			var args = splitIdx<0 ? "" : cmd.command.substr(splitIdx+1);
			print("Executing: "+name+" "+args, White);
			separator();
			var proc = js.node.ChildProcess.spawn(name, [args], { cwd:p.getProjectDir() });
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
			jKill.click(_->{
				print("Sent kill signal!", 0xff5555);
				needManualClosing = true;
				proc.kill();
			});
		}
		else {
			// No command
			jKill.prop("disabled", true);
		}
	}


	public static function runMultipleCommands(p:data.Project, cmds:Array<ldtk.Json.CustomCommand>, onComplete:Void->Void) {
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