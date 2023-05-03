package ui.modal;

class ToolPalettePopOut extends ui.Modal {
	static var LEAVE_DIST_BEFORE_CLOSING = 30;
	static var OVER_PADDING = 64;

	public static var ME : Null<ToolPalettePopOut>;

	var palette : ToolPalette;
	var lastMouseX : Null<Float>;
	var lastMouseY : Null<Float>;
	var leavingElapsedDist = 0.;

	public function new(p:ToolPalette) {
		super();

		ME = this;
		palette = p;
		jContent.append(palette.jContent);

		jModalAndMask.addClass("popOutPalette");
		App.ME.jDoc.off(".popOutPaletteEvent");

		jWrapper.mousedown( onWrapperMouseDown );
		App.ME.jDoc
			.on("mousemove.popOutPaletteEvent", onDocMouseMove)
			.on("mouseup.popOutPaletteEvent", onDocMouseUp);

		// Positionning
		jMask.css("opacity",0);
		var jPalette = editor.jPalette;
		jWrapper.offset({
			left: jPalette.offset().left,
			top: jPalette.offset().top,
		});
		jWrapper.css("height", jPalette.outerHeight());
	}

	override function countAsModal():Bool {
		return false;
	}

	function onDocMouseMove(ev:js.jquery.Event) {
		if( lastMouseX!=null ) {
			var wid = jWrapper.outerWidth();
			var hei = jWrapper.outerHeight();
			var modalX1 = jWrapper.offset().left;
			var modalY1 = jWrapper.offset().top;
			var modalX2 = modalX1 + wid;
			var modalY2 = modalY1 + hei;

			if( isMouseDown || ev.pageX>=modalX1 && ev.pageX<=modalX2 && ev.pageY>=modalY1 && ev.pageY<=modalY2 ) {
				// Over modal or dragging
				leavingElapsedDist = 0;
			}
			else if( ev.pageY<modalY1 && ev.pageX<editor.jMainPanel.outerWidth() )
				close();
			else {
				// Out of modal: try to determine if the cursor is moving away from the modal bounds
				// 1 2
				// 4 3
				var angToCenter = Math.atan2((modalY1+hei*0.5)-ev.pageY, (modalX1+wid*0.5)-ev.pageX);
				var angDeltaCorner1 = M.radSubstract( angToCenter, Math.atan2(modalY1-ev.pageY, modalX1-ev.pageX) );
				var angDeltaCorner2 = M.radSubstract( angToCenter, Math.atan2(modalY1-ev.pageY, modalX2-ev.pageX) );
				var angDeltaCorner3 = M.radSubstract( angToCenter, Math.atan2(modalY2-ev.pageY, modalX2-ev.pageX) );
				var angDeltaCorner4 = M.radSubstract( angToCenter, Math.atan2(modalY2-ev.pageY, modalX1-ev.pageX) );
				var minDelta = M.fmin( angDeltaCorner1, M.fmin(angDeltaCorner2, M.fmin( angDeltaCorner3, angDeltaCorner4)) );
				var maxDelta = M.fmax( angDeltaCorner1, M.fmax(angDeltaCorner2, M.fmax( angDeltaCorner3, angDeltaCorner4)) );
				minDelta-=0.35;
				maxDelta+=0.35;

				var angDeltaMouse = M.radSubstract( angToCenter, Math.atan2(ev.pageY-lastMouseY, ev.pageX-lastMouseX) );
				var mouseDist = M.dist(lastMouseX, lastMouseY, ev.pageX, ev.pageY);

				if( angDeltaMouse>=minDelta && angDeltaMouse<=maxDelta )
					leavingElapsedDist-=mouseDist*3; // mouse is moving toward the modal
				else
					leavingElapsedDist+=mouseDist; // mouse is moving away
				leavingElapsedDist = M.fmax(0, leavingElapsedDist);

				if( leavingElapsedDist>=LEAVE_DIST_BEFORE_CLOSING ) {
					if( cd.has("suspendAutoClosing") )
						cd.setS("needClosing",Const.INFINITE);
					else
						close();
				}
				else
					cd.unset("needClosing");
			}
		}

		lastMouseX = ev.pageX;
		lastMouseY = ev.pageY;
	}

	var isMouseDown = false;
	function onWrapperMouseDown(ev:js.jquery.Event) {
		isMouseDown = true;
	}

	function onDocMouseUp(ev:js.jquery.Event) {
		isMouseDown = false;
		leavingElapsedDist = 0;
		cd.setS("suspendAutoClosing",0.2);
	}

	override function close() {
		palette.onPopBackIn();
		super.close();
	}

	override function onDispose() {
		super.onDispose();
		App.ME.jDoc.off(".popOutPaletteEvent");

		if( ME==this )
			ME = null;
	}

	public static function isOpen() {
		return ME!=null && !ME.isClosing();
	}

	override function update() {
		super.update();

		if( !cd.has("suspendAutoClosing") && cd.has("needClosing") )
			close();
	}
}
