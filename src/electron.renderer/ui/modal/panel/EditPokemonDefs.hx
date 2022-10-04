package ui.modal.panel;

class EditPokemonDefs extends ui.modal.Panel {
	public function new() {
		super();

		// Main page
		linkToButton("button.editPokemons");
		loadTemplate("editPokemonDefs");
	}
}
