package tool;

class EmptyTool extends Tool<Int> {
	public function new() {
		super();
		N.debug("using empty tool");
	}

	override function updatePalette() {
		super.updatePalette();
	}
}