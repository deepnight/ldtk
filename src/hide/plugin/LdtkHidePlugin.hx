package hide.plugin;

import js.Browser.document;
import js.Browser.window;
import js.node.Fs;
import js.node.Os;
import js.node.Path;

import hide.plugin.HideExterns.Ide;
import hide.plugin.HideExterns.View;

class LdtkHidePlugin extends View {
	static inline var COMPONENT = "ldtk.LdtkView";
	static var selfDir:Null<String> = null;

	var webview:Dynamic;

	public function new(state:Dynamic) {
		super(state);
	}

	override function getTitle():String {
		return "LDtk";
	}

	static function cfg(key:String, def:Null<String>):Null<String> {
		return try {
			var v:Null<String> = Ide.inst.config.current.get(key);
			v != null ? v : def;
		} catch (e:Dynamic) def;
	}

	static function getAppDir():Null<String> {
		var c = cfg("ldtk.appDir", null);
		if (c != null) return c;
		return selfDir != null ? Path.dirname(selfDir) : null;
	}

	static function getProject():Null<String> {
		var p = cfg("ldtk.project", null);
		return p != null ? Path.resolve(Ide.inst.getPath(p)) : null;
	}

	static function getDbPath():Null<String> {
		var ide = Ide.inst;
		return ide.databaseFile != null ? Path.resolve(ide.getPath(ide.databaseFile)) : null;
	}

	static function bridgeFilePath():String {
		var key = getDbPath() ?? "none";
		var h = 5381;
		for (i in 0...key.length)
			h = (h * 33 + StringTools.fastCodeAt(key, i)) | 0;
		return Path.join(Os.tmpdir(), "hide-ldtk-live-" + StringTools.hex(h, 8).toLowerCase() + ".cdb");
	}

	static var lastDump = 0.0;

	static function refreshBridgeFile(force:Bool) {
		var now = Date.now().getTime();
		if (!force && now - lastDump < 1000) return;
		lastDump = now;
		try {
			Fs.writeFileSync(bridgeFilePath(), Ide.inst.database.save());
		} catch (e:Dynamic) {
			js.Browser.console.error("[ldtk-hide] live cdb dump failed", e);
		}
	}

	override function onDisplay() {
		var root:js.html.Element = element.get(0);
		var appDir = getAppDir();
		if (appDir == null) {
			root.innerHTML = "<div style='padding:24px;color:#c66'>LDtk app dir not found — set \"ldtk.appDir\" in props.json</div>";
			return;
		}
		refreshBridgeFile(true);

		var params = new js.html.URLSearchParams();
		params.set("embed", "1");
		var project = getProject();
		if (project != null) params.set("project", project);
		var dbPath = getDbPath();
		if (dbPath != null) {
			params.set("bridgeSrc", dbPath);
			params.set("bridgeFile", bridgeFilePath());
		}
		var url = "file://" + appDir + "/nwjs/host.html?" + Std.string(params);

		root.innerHTML = "";
		root.style.padding = "0";

		var wv = document.createElement("webview");
		wv.setAttribute("allownw", "");
		wv.setAttribute("partition", "trusted");
		wv.setAttribute("autosize", "on");
		wv.style.cssText = "width:100%;height:100%;border:0;display:block;background:#1e2229";
		root.appendChild(wv);
		wv.setAttribute("src", url);
		webview = wv;

		root.addEventListener("mouseenter", _ -> refreshBridgeFile(false));
	}

	override function onBeforeClose():Bool {
		return window.confirm("Close the LDtk tab? Unsaved LDtk changes will be lost.");
	}

	override function destroy() {
		webview = null;
		super.destroy();
	}

	static function main() {
		var src:String = document.currentScript != null ? (cast document.currentScript).src : "";
		if (StringTools.startsWith(src, "file://"))
			selfDir = Path.dirname(js.Syntax.code("decodeURIComponent({0})", src.substr(7)));

		js.Node.global.__hideLdtkBridge = {
			readFile: function(absPath:String):Null<String> {
				return try {
					var dbPath = getDbPath();
					if (dbPath == null || Path.resolve(absPath) != dbPath) null;
					else Ide.inst.database.save();
				} catch (e:Dynamic) null;
			},
		};

		var cl:Dynamic = LdtkHidePlugin;
		cl.__name__ = COMPONENT;
		js.Syntax.code("{0}.prototype.__class__ = {0}", cl);
		js.Syntax.code("$hxClasses[{0}] = {1}", COMPONENT, cl);
		View.register(cast LdtkHidePlugin);
	}
}
