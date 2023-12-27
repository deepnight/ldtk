package ui;

typedef SearchElement = {
	var desc: String;
	var onPick: Void->Void;
	var ?keywords: String;
}

class CommandPalette {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jCmdPal: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	var jInput: js.jquery.JQuery;
	var jResults: js.jquery.JQuery;
	var jMask: js.jquery.JQuery;

	var cleanReg = ~/[^a-z0-9 _]+/gi;
	var allElements : Array<SearchElement> = [];
	var curElements : Array<SearchElement> = [];

	public function new() {
		var jXml = App.ME.jPage.find("xml.commandPalette");
		jCmdPal = jXml.children().clone().wrapAll('<div id="commandPalette"></div>').parent();
		App.ME.jPage.append(jCmdPal);

		jMask = jCmdPal.find(".mask");
		jWrapper = jCmdPal.find(".wrapper");
		jInput = jCmdPal.find("input[type=text]");
		jResults = jCmdPal.find(".results");

		jMask.click(_->close());

		jInput.keydown( (ev:js.jquery.Event)->{
			switch ev.key {
				case "Escape": close();
			}
		});
		jInput.on("input", _->applySearch() );
		jInput.blur( _->jInput.focus() );
		jInput.focus();

		for(w in project.worlds) {
			allElements.push({
				desc: "World: "+w.identifier,
				onPick: ()->editor.selectWorld(w,true),
			});
			for(l in w.levels) {
				allElements.push({
					desc: "Level: "+l.identifier,
					onPick: ()->{
						editor.selectLevel(l, true);
						editor.setWorldMode(false);
					},
				});
			}
		}

		for(e in allElements) {
			if( e.keywords==null )
				e.keywords = e.desc.toLowerCase();
			e.keywords = cleanupKeywords(e.keywords);
		}

		applySearch();
	}

	function cleanupKeywords(raw:String) {
		return raw==null ? "" : cleanReg.replace(raw, " ").toLowerCase();
	}

	function applySearch() {
		curElements = [];
		var raw = cleanupKeywords( jInput.val() );
		for(e in allElements) {
			if( e.keywords.indexOf(raw)>=0 )
				curElements.push(e);
		}

		jResults.empty();
		for(e in curElements) {
			var jElement = new J('<div class="element">${e.desc}</div>');
			jElement.click(_->{
				close();
				e.onPick();
			});
			jElement.appendTo(jResults);
		}
	}

	function close() {
		jCmdPal.remove();
		jCmdPal = null;
	}
}