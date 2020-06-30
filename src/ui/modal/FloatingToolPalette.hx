package ui.modal;

class FloatingToolPalette extends ui.Modal {
	static var LEAVE_DIST_BEFORE_CLOSING = 90;
	static var OVER_PADDING = 64;

	public static var ME : Null<FloatingToolPalette>;
	public var isPopOut = true;

	var tool : Tool<Dynamic>;
	var lastMouseX : Null<Float>;
	var lastMouseY : Null<Float>;
	var leavingElapsedDist = 0.;

	public function new(t:Tool<Dynamic>, isPopOut:Bool) {
		super();

		ME = this;
		tool = t;
		this.isPopOut = isPopOut;

		jModalAndMask.addClass("floatingPalette");
		updatePalette();
		client.jDoc.off(".floatingPaletteEvent");

		if( isPopOut ) {
			jWrapper.mousedown( onWrapperMouseDown );
			client.jDoc
				.on("mousemove.floatingPaletteEvent", onDocMouseMove)
				.on("mouseup.floatingPaletteEvent", onDocMouseUp);
		}

		// Detect middle click to close
		if( !isPopOut ) {
			var startX = 0.;
			var startY = 0.;
			jModalAndMask
				.mousedown( function(ev) {
					startX = ev.pageX;
					startY = ev.pageY;
				} )
				.mouseup( function(ev) {
					if( ev.button==1 && M.dist(startX, startY, ev.pageX, ev.pageY)<Const.MIDDLE_CLICK_DIST_THRESHOLD )
						close();
				});
		}

		// Positionning
		if( isPopOut ) {
			jMask.css("opacity",0);
			var jPalette = client.jPalette;
			jWrapper.offset({
				left: jPalette.offset().left,
				top: jPalette.offset().top,
			});
			jWrapper.css("height", jPalette.outerHeight());
			// jWrapper.css("height", js.Browser.window.innerHeight - jWrapper.offset().top);
		}
		else {
			var m = client.getMouse();
			var x = m.htmlX - jWrapper.outerWidth()*0.5;
			var y = m.htmlY - jWrapper.outerHeight()*0.5;
			jWrapper.offset({
				left: M.fclamp(x, 0, js.Browser.window.innerWidth-jWrapper.outerWidth()),
				top: M.fclamp(y, 0, js.Browser.window.innerHeight-jWrapper.outerHeight()),
			});
		}
	}


	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		if( e==ToolOptionChanged )
			updatePalette();
	}

	function updatePalette() {
		jContent.empty();
		jContent.append( tool.createPalette() );
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
				minDelta-=0.1;
				maxDelta+=0.1;

				var angDeltaMouse = M.radSubstract( angToCenter, Math.atan2(ev.pageY-lastMouseY, ev.pageX-lastMouseX) );
				var mouseDist = M.dist(lastMouseX, lastMouseY, ev.pageX, ev.pageY);

				if( angDeltaMouse>=minDelta && angDeltaMouse<=maxDelta )
					leavingElapsedDist-=mouseDist*3; // mouse is moving toward the modal
				else
					leavingElapsedDist+=mouseDist; // mouse is moving away
				leavingElapsedDist = M.fmax(0, leavingElapsedDist);

				// Close
				if( leavingElapsedDist>=LEAVE_DIST_BEFORE_CLOSING )
					close();
			}
			// Client.ME.debug("leaveDist = "+Std.int(leavingElapsedDist));
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
	}


	override function onDispose() {
		super.onDispose();
		client.jDoc.off(".floatingPaletteEvent");
		if( !tool.destroyed )
			tool.updatePalette();
		if( ME==this )
			ME = null;
	}

	public static function isOpen() {
		return ME!=null && !ME.isClosing();
	}
}
