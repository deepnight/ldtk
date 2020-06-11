package tool;

class EmptyTool extends Tool<Int> {
	public function new() {
		super();
	}

	override function getSelectedValue():Int {
		return -1;
	}

	override function getDefaultValue():Int {
		return -1;
	}

	override function canBeUsed():Bool {
		return true;
	}

	override function updatePalette() {
		super.updatePalette();
	}
}