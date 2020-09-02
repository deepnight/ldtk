package ui;

class ToolPalette {
	public var jContent : js.jquery.JQuery;
	var tool : Tool<Dynamic>;

	// Optional list object (not used for Tileset for example)
	var jList : Null<js.jquery.JQuery>;
	var listScrollY = 0.;
	var listTargetY : Null<Float>;

	public function new(t:Tool<Dynamic>) {
		tool = t;
		N.error("new ToolPalette: "+tool);
		jContent = new J('<div class="palette"/>');
	}

	public function focusOnSelection() {
	}

	public final function render() {
		jContent.off().empty();
		doRender();

		if( jList!=null ) {
			// Cancel Focus scroll animation
			jList.on("mousewheel mousedown", function(ev) listTargetY = null );

			// Scroll Y memory
			jList.scroll(function(ev) {
				listScrollY = jList.scrollTop();
			});
			jList.scrollTop(listScrollY);
		}
	}

	function doRender() {}

	function animateListScrolling(toY:Float) {
		listTargetY = toY + jList.scrollTop() - jList.outerHeight()*0.5;
		listTargetY = M.fclamp(listTargetY, 0, jList.prop("scrollHeight")- jList.outerHeight());
	}

	public function update() {
		// Focus auto-scroll animation
		if( jList!=null && listTargetY!=null ) {
			var jList = jContent.find(">ul");
			var curY = jList.scrollTop();
			if( M.fabs(listTargetY-curY)>=3 )
				jList.scrollTop( curY + ( listTargetY-curY )*0.25 * Editor.ME.tmod );
			else {
				jList.scrollTop(listTargetY);
				listTargetY = null;
			}
		}
	}
}