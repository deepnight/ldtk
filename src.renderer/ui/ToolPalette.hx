package ui;

class ToolPalette {
	public var jContent : js.jquery.JQuery;
	var tool : Tool<Dynamic>;
	var canPopOut = false;
	var isPoppedOut = false;

	// Optional scrollable list stuff
	var jList : Null<js.jquery.JQuery>;
	var listScrollY = 0.;
	var listTargetY : Null<Float>;

	// Pop-out stuff
	var jPlaceholder: Null<js.jquery.JQuery>;

	public function new(t:Tool<Dynamic>) {
		tool = t;
		jContent = new J('<div class="palette"/>');
	}

	public function focusOnSelection() {
	}

	public final function render() {
		jContent.off().empty();

		doRender();

		// Pop-out
		jContent.mouseover( function(ev) {
			if( canPopOut && !isPoppedOut )
				popOut();
		});

		if( jList!=null ) {
			// Cancel Focus scrolling animation
			jList.on("mousewheel mousedown", function(ev) listTargetY = null );

			// Scroll Y memory
			jList.scroll(function(ev) {
				listScrollY = jList.scrollTop();
			});
			jList.scrollTop(listScrollY);
		}
	}

	function doRender() {}

	function popOut() {
		isPoppedOut = true;

		jPlaceholder = new J('<div class="toolPopOutPlaceholder"/>');
		jPlaceholder.insertBefore(jContent);

		new ui.modal.ToolPalettePopOut(this);
	}

	@:allow(ui.modal.ToolPalettePopOut)
	function onPopBackIn() {
		if( !isPoppedOut )
			return;

		isPoppedOut = false;

		jContent.insertBefore(jPlaceholder);

		jPlaceholder.remove();
		jPlaceholder = null;
	}

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
				jList.scrollTop( curY + ( listTargetY-curY )*0.25 );
			else {
				jList.scrollTop(listTargetY);
				listTargetY = null;
			}
		}
	}
}