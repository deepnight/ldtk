package ui.modal.panel;

class EditPokemonDefs extends ui.modal.Panel {
	var curPokemon : Null<data.def.PokemonDef>;

	public function new() {
		super();

		// Main page
		linkToButton("button.editPokemons");
		loadTemplate("editPokemonDefs");

		// Import
		jContent.find("button.import").click( ev->{
			var ctx = new ContextMenu(ev);
			ctx.add({
				label: L.t._("CSV - Ulix Dexflow"),
				sub: L.t._('Expected format:\n - One entry per line\n - Fields separated by column'),
				cb: ()->{
					dn.js.ElectronDialogs.openFile([".csv"], project.getProjectDir(), function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						switch dn.FilePath.extractExtension(absPath,true) {
							case "csv":
								var i = new importer.Pokemon();
								var csv = i.load( project.makeRelativeFilePath(absPath) );
								updatePokemonList(csv);
							case _:
								N.error('The file must have the ".csv" extension.');
						}
					});
				},
			});
			// updatePokemonList(csv);
		});
	}

	function updatePokemonList(csv:Map<String, Array<String>>) {

		var jEnumList = jContent.find(".pokemonList>ul");
		jEnumList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jEnumList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

		for(n in csv["name"]) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.data("uid", Std.parseInt(n));
			jLi.append('<span class="name">'+n+'</span>');
		}
	}
}