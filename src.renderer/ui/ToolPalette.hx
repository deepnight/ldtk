package ui;

class ToolPalette {
	public var jContent : js.jquery.JQuery;
	var tool : Tool<Dynamic>;

	public function new(t:Tool<Dynamic>) {
		tool = t;
		N.error("new ToolPalette: "+tool);
		jContent = new J('<div class="palette"/>');
	}

	public function focusOnSelection() {
	}

	public function render() {
		jContent.off().empty();
	}
}