import sys.io.Process;

class Setup {
	public static function main() {
		var cmd;
		cmd = runCommand("haxelib install ase --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib install uuid --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib install format --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib git castle https://github.com/deepnight/castle --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib git heaps https://github.com/deepnight/heaps.git --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib git electron https://github.com/tong/hxelectron.git --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib git hxnodejs https://github.com/HaxeFoundation/hxnodejs.git --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("haxelib git heaps-aseprite https://github.com/AustinEast/heaps-aseprite.git --always");
		Sys.println(cmd.stdout);

		cmd = runCommand("git branch --show-current");

		var branch = cmd.stdout;

		if (Sys.args().length > 0) {
			branch = Sys.args()[0];
		}

		Sys.println("On Branch '" + branch + "'");

		cmd = runCommand("haxelib git ldtk-haxe-api https://github.com/deepnight/ldtk-haxe-api.git " + branch + " --always");

		if (cmd.code == 0) {
			Sys.println(cmd.stdout);
		} else {
			cmd = runCommand("haxelib remove ldtk-haxe-api");
			Sys.println(cmd.stdout);

			cmd = runCommand("haxelib git ldtk-haxe-api https://github.com/deepnight/ldtk-haxe-api.git master --always");
			Sys.println(cmd.stdout);
		}

		cmd = runCommand("haxelib git deepnightLibs https://github.com/deepnight/deepnightLibs.git master --always");
		Sys.println(cmd.stdout);
	}

	static function runCommand(cmd:String) {
		Sys.println("\n-\n> " + cmd);
		var proc = new Process(cmd, null);
		var output = "";
		try {
			while (true) {
				output += proc.stdout.readLine() + "\n";
			}
		} catch (e) {
			// Eat Eof
		}

		output += proc.stdout.readAll().toString();
		output += proc.stderr.readAll().toString();

		var code = proc.exitCode(true);

		proc.close();

		return new ProcessResult(code, StringTools.trim(output));
	}
}

class ProcessResult {
	public var code:Int;
	public var stdout:String;

	public function new(code:Int, stdout:String) {
		this.code = code;
		this.stdout = stdout;
	}
}
