package ui.modal.panel;

class EditPokemonDefs extends ui.modal.Panel {
	// var curEnum : Null<data.def.EnumDef>;
	var curPokemon : Null<data.def.PokemonDef>;

	public function new() {
		super();

		// Main page
		linkToButton("button.editPokemons");
		loadTemplate("editPokemonDefs");
		updateEnumList();
	}

	function updateEnumList() {
		var csv = Const.getPokemonCsv();

		trace(project.defs.pokemons);
		var jEnumList = jContent.find(".pokemonList>ul");
		jEnumList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jEnumList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);


		for(ed in csv["name"]) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.data("uid", Std.parseInt(ed));
			jLi.append('<span class="name">'+ed+'</span>');
		}
	}
}