package ui;

class TilesetPicker {
	static var SCROLL_MEMORY : Map<Int, { x:Float, y:Float, zoom:Float }> = new Map();

	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return new J(js.Browser.document);

	var jPicker : js.jquery.JQuery;
	var jAtlas : js.jquery.JQuery;
	var jImg : js.jquery.JQuery;

	var tool : tool.TileTool;
	var zoom(default,set) : Float;
	var jCursors : js.jquery.JQuery;
	var jSelections : js.jquery.JQuery;

	var dragStart : Null<{ bt:Int, pageX:Float, pageY:Float }>;

	var scrollX(default,set) : Float;
	var scrollY(default,set) : Float;

	public function new(target:js.jquery.JQuery, tool:tool.TileTool) {
		this.tool = tool;

		// Create picker elements
		jPicker = new J('<div class="tilesetPicker"/>');
		jPicker.appendTo(target);

		jAtlas = new J('<div class="wrapper"/>');
		jAtlas.appendTo(jPicker);

		jCursors = new J('<div class="cursorsWrapper"/>');
		jCursors.prependTo(jAtlas);

		jSelections = new J('<div class="selectionsWrapper"/>');
		jSelections.prependTo(jAtlas);

		var jImg = new J( tool.curTilesetDef.createAtlasHtmlImage() );
		jImg.appendTo(jAtlas);
		jImg.addClass("atlas");

		// Init events
		jPicker.mousedown( function(ev) {
			ev.preventDefault();
			onPickerMouseDown(ev);
			jDoc
				.off(".pickerDragEvent")
				.on("mouseup.pickerDragEvent", onDocMouseUp)
				.on("mousemove.pickerDragEvent", onDocMouseMove);
		});

		jPicker.get(0).onwheel = onPickerMouseWheel;
		jPicker.mousemove( onPickerMouseMove );

		// jAtlas.css("min-width", tool.curTilesetDef.pxWid+"px");
		// jAtlas.css("min-height", tool.curTilesetDef.pxHei+"px");
		loadScrollPos();
		renderSelection();

		// Force picker dimensions as soon as img is rendered
		// jImg.on("load", function(ev) {
		// 	jPicker.css("width",jPicker.innerWidth()+"px");
		// 	jPicker.css("height",jPicker.innerHeight()+"px");
		// });
	}


	function loadScrollPos() {
		var mem = SCROLL_MEMORY.get(tool.curTilesetDef.uid);
		if( mem!=null ) {
			scrollX = mem.x;
			scrollY = mem.y;
			zoom = mem.zoom;
		}
		else {
			scrollX = 0;
			scrollY = 0;
			zoom = 3;
		}
	}

	function saveScrollPos() {
		SCROLL_MEMORY.set(tool.curTilesetDef.uid, { x:scrollX, y:scrollY, zoom:zoom });
	}

	function set_zoom(v) {
		zoom = M.fclamp(v, 0.5, 6);
		jAtlas.css("zoom",zoom);
		saveScrollPos();
		return zoom;
	}

	inline function set_scrollX(v:Float) {
		scrollX = v;
		jAtlas.css("margin-left",-scrollX);
		saveScrollPos();
		return v;
	}

	inline function set_scrollY(v:Float) {
		scrollY = v;
		jAtlas.css("margin-top",-scrollY);
		saveScrollPos();
		return v;
	}

	inline function pageXtoLocal(v:Float) return M.round( ( v - jPicker.offset().left ) / zoom + scrollX );
	inline function pageYtoLocal(v:Float) return M.round( ( v - jPicker.offset().top ) / zoom + scrollY );

	function renderSelection() {
		jSelections.empty();
		jSelections.append( createCursor(tool.getSelectedValue(),"selection") );
	}


	function createCursor(sel:TilesetSelection, ?subClass:String, ?cWid:Int, ?cHei:Int) {
		var wrapper = new J("<div/>");
		var idsMap = new Map();
		for(tileId in sel.ids)
			idsMap.set(tileId,true);
		inline function hasCursorAt(cx:Int,cy:Int) {
			return idsMap.exists( tool.curTilesetDef.getTileId(cx,cy) );
		}

		var individualMode = sel.rand;

		for(tileId in sel.ids) {
			var x = tool.curTilesetDef.getTileSourceX(tileId);
			var y = tool.curTilesetDef.getTileSourceY(tileId);
			var cx = tool.curTilesetDef.getTileCx(tileId);
			var cy = tool.curTilesetDef.getTileCy(tileId);

			var e = new J('<div class="tileCursor"/>');
			e.appendTo(wrapper);
			if( subClass!=null )
				e.addClass(subClass);

			if( individualMode )
				e.addClass("allBorders");
			else {
				if( !hasCursorAt(cx-1,cy) ) e.addClass("left");
				if( !hasCursorAt(cx+1,cy) ) e.addClass("right");
				if( !hasCursorAt(cx,cy-1) ) e.addClass("top");
				if( !hasCursorAt(cx,cy+1) ) e.addClass("bottom");
			}

			e.css("left", x+"px");
			e.css("top", y+"px");
			var grid = tool.curTilesetDef.tileGridSize;
			e.css("width", ( cWid!=null ? cWid*grid : tool.curTilesetDef.tileGridSize )+"px");
			e.css("height", ( cHei!=null ? cHei*grid : tool.curTilesetDef.tileGridSize )+"px");
		}

		return wrapper;
	}



	var _lastRect = null;
	function updateCursor(pageX:Float, pageY:Float, force=false) {
		if( isScrolling() || Client.ME.isKeyDown(K.SPACE) ) {
			jCursors.hide();
			return;
		}

		Client.ME.debug(pageX+","+pageY+" => "+pageXtoLocal(pageX)+","+pageYtoLocal(pageY));
		Client.ME.debug("scroll="+scrollX+","+scrollY, true);
		Client.ME.debug("pickerSize="+jPicker.innerWidth()+"x"+jPicker.innerHeight(), true);
		var img = jAtlas.find("img.atlas");
		Client.ME.debug("img="+img.innerWidth()+"x"+img.innerHeight(), true);

		var r = getCursorRect(pageX, pageY);

		// Avoid re-render if it's the same rect
		if( !force && _lastRect!=null && r.cx==_lastRect.cx && r.cy==_lastRect.cy && r.wid==_lastRect.wid && r.hei==_lastRect.hei )
			return;

		var tileId = tool.curTilesetDef.getTileId(r.cx,r.cy);
		jCursors.empty();
		jCursors.show();

		var saved = tool.curTilesetDef.getSavedSelectionFor(tileId);
		if( saved==null || dragStart!=null ) {
			var c = createCursor({ rand:tool.isRandomMode(), ids:[tileId] }, dragStart!=null && dragStart.bt==2?"remove":null, r.wid, r.hei);
			c.appendTo(jCursors);
		}
		else {
			// Saved-selection rollover
			jCursors.append( createCursor(saved) );
		}

		_lastRect = r;
	}

	function scroll(newPageX:Float, newPageY:Float) {
		var spd = 1.;

		scrollX -= ( newPageX - dragStart.pageX ) / zoom * spd;
		dragStart.pageX = newPageX;

		scrollY -= ( newPageY - dragStart.pageY ) / zoom * spd;
		dragStart.pageY = newPageY;
	}

	inline function isScrolling() {
		return dragStart!=null && ( dragStart.bt==1 || Client.ME.isKeyDown(K.SPACE) );
	}

	function onDocMouseMove(ev:js.jquery.Event) {
		updateCursor(ev.pageX, ev.pageY);

		if( isScrolling() )
			scroll(ev.pageX, ev.pageY);
	}

	function onDocMouseUp(ev:js.jquery.Event) {
		jDoc.off(".pickerDragEvent");

		// Apply selection
		if( dragStart!=null && !isScrolling() ) {
			var r = getCursorRect(ev.pageX, ev.pageY);
			if( r.wid==1 && r.hei==1 )
				applySelection([ tool.curTilesetDef.getTileId(r.cx,r.cy) ], dragStart.bt!=2);
			else {
				var tileIds = [];
				for(cx in r.cx...r.cx+r.wid)
				for(cy in r.cy...r.cy+r.hei)
					tileIds.push( tool.curTilesetDef.getTileId(cx,cy) );
				applySelection(tileIds, dragStart.bt!=2);
			}
		}

		dragStart = null;
		updateCursor(ev.pageX, ev.pageY, true);
	}

	function applySelection(selIds:Array<Int>, add:Bool) {
		// Auto-pick saved selection
		if( selIds.length==1 && tool.curTilesetDef.hasSavedSelectionFor(selIds[0]) ) {
			// Check if the saved selection isn't already picked. If so, just pick the sub-tile
			var sel = tool.getSelectedValue();
			var saved = tool.curTilesetDef.getSavedSelectionFor( selIds[0] );
			var same = true;
			var i = 0;
			while( i<saved.ids.length ) {
				if( sel.ids[i]!=saved.ids[i] )
					same = false;
				i++;
			}
			if( !same ) {
				selIds = saved.ids.copy();
				tool.setRandomMode( saved.rand );
			}
		}

		var curSel = tool.getSelectedValue();
		if( add ) {
			if( !Client.ME.isShiftDown() && !Client.ME.isCtrlDown() ) {
				// Replace active selection with this one
				tool.selectValue({ rand:tool.isRandomMode(), ids:selIds });
			}
			else {
				// Add selection (OR)
				var idMap = new Map();
				for(tid in tool.getSelectedValue().ids)
					idMap.set(tid,true);
				for(tid in selIds)
					idMap.set(tid,true);

				var arr = [];
				for(tid in idMap.keys())
					arr.push(tid);
				tool.selectValue({ rand:tool.isRandomMode(), ids:arr });
			}
		}
		else {
			// Substract selection
			var remMap = new Map();
			for(tid in selIds)
				remMap.set(tid, true);

			var i = 0;
			while( i<curSel.ids.length && curSel.ids.length>1 )
				if( remMap.exists(curSel.ids[i]) )
					curSel.ids.splice(i,1);
				else
					i++;
		}

		renderSelection();
	}

	function onRemoveSel(rem:Array<Int>) {
	}


	function onPickerMouseWheel(ev:js.html.WheelEvent) {
		if( ev.deltaY!=0 ) {
			ev.preventDefault();
			var oldLocalX = pageXtoLocal(ev.pageX);
			var oldLocalY = pageYtoLocal(ev.pageY);

			zoom += -ev.deltaY*0.001 * zoom;

			var newLocalX = pageXtoLocal(ev.pageX);
			var newLocalY = pageYtoLocal(ev.pageY);
			scrollX += ( oldLocalX - newLocalX );
			scrollY += ( oldLocalY - newLocalY );
		}
	}

	function onPickerMouseDown(ev:js.jquery.Event) {
		dragStart = {
			bt: ev.button,
			pageX: ev.pageX,
			pageY: ev.pageY,
		}

		// Block context menu
		if( ev.button==2 )
			jDoc.on("contextmenu.pickerCtxCatcher", function(ev) {
				ev.preventDefault();
				jDoc.off(".pickerCtxCatcher");
			});
	}

	function onPickerMouseMove(ev:js.jquery.Event) {
		updateCursor(ev.pageX, ev.pageY);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var localX = pageXtoLocal(pageX);
		var localY = pageYtoLocal(pageY);

		var grid = tool.curTilesetDef.tileGridSize;
		var cx = M.iclamp( Std.int( localX / grid ), 0, tool.curTilesetDef.cWid-1 );
		var cy = M.iclamp( Std.int( localY / grid ), 0, tool.curTilesetDef.cHei-1 );

		if( dragStart==null )
			return {
				cx: cx,
				cy: cy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = M.iclamp( Std.int( pageXtoLocal(dragStart.pageX) / grid ), 0, tool.curTilesetDef.cWid-1 );
			var startCy = M.iclamp( Std.int( pageYtoLocal(dragStart.pageY) / grid ), 0, tool.curTilesetDef.cHei-1 );
			return {
				cx: M.imin(cx,startCx),
				cy: M.imin(cy,startCy),
				wid: M.iabs(cx-startCx) + 1,
				hei: M.iabs(cy-startCy) + 1,
			}
		}
	}
}