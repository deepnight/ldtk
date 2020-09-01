package ui;

class ToolPalette {
	public var jContent : js.jquery.JQuery;
	var tool : Tool<Dynamic>;

	public function new(t:Tool<Dynamic>) {
		tool = t;
		jContent = new J('<div class="palette"/>');
	}

	public function render() {
		jContent.off().empty();
	}
}