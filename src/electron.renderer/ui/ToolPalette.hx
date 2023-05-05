package ui;

class ToolPalette {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jPaletteOptions : js.jquery.JQuery;

	public var jContent : js.jquery.JQuery;
	var tool : Tool<Dynamic>;
	@:allow(Tool)
	var isPoppedOut = false;

	// Optional scrollable list stuff
	var jList : Null<js.jquery.JQuery>;
	var listScrollY = 0.;
	var listTargetY : Null<Float>;

	// Pop-out stuff
	var jPlaceholder: Null<js.jquery.JQuery>;

	public function new(t:Tool<Dynamic>) {
		tool = t;
		jPaletteOptions = editor.jMainPanel.find("#paletteOptions");
		jPaletteOptions.empty();
		jContent = new J('<div class="palette"/>');
	}

	public function focusOnSelection(immediate=false) {
	}

	public function onShow() {
		focusOnSelection(true);
	}

	public function onHide() {}

	public final function render() {
		jContent.off().empty();

		doRender();

		// Pop-out
		jContent.mouseover( function(ev) {
			if( needToPopOut() && !isPoppedOut && !Editor.ME.curTool.isRunning() )
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

	function makeBgActiveColor(c:Int) : String {
		return C.intToHex( C.toWhite(c, 0.66) );
	}

	function makeBgInactiveColor(c:Int) : String {
		return C.intToHex( C.interpolateInt( c, 0x313843, 0.72 ) );
	}

	function makeTextInactiveColor(c:Int) : String {
		return C.intToHex( C.toWhite(c, 0.3) );
	}

	/** Called when a WASD key is pressed. Should return TRUE to cancel event bubbling. **/
	public function onNavigateSelection(dx:Int, dy:Int, pressed:Bool) {
		return false;
	}

	function doRender() {}

	function needToPopOut() {
		return false;
	}

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
				jList.scrollTop( curY + ( listTargetY-curY )*0.4 );
			else {
				jList.scrollTop(listTargetY);
				listTargetY = null;
			}
		}
	}
}