package ui;

class TilesetPicker {
	static var SCROLL_MEMORY : Map<Int, { x:Float, y:Float, zoom:Float }> = new Map();

	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return new J(js.Browser.document);

	var tilesetDef : led.def.TilesetDef;
	var tool : Null<tool.TileTool>;

	var jPicker : js.jquery.JQuery;
	var jAtlas : js.jquery.JQuery;
	var jCursor : js.jquery.JQuery;
	var jSelection : js.jquery.JQuery;

	var zoom(default,set) : Float;
	var dragStart : Null<{ bt:Int, pageX:Float, pageY:Float }>;
	var scrollX(default,set) : Float;
	var scrollY(default,set) : Float;

	public var singleSelectedTileId(default,set) : Null<Int>;
	var singleTileMode(get,never) : Bool;
		inline function get_singleTileMode() return tool==null;


	public function new(target:js.jquery.JQuery, td:led.def.TilesetDef, ?tool:tool.TileTool) {
		tilesetDef = td;
		this.tool = tool;

		// Create picker elements
		jPicker = new J('<div class="tilesetPicker"/>');
		jPicker.appendTo(target);
		if( singleTileMode )
			jPicker.addClass("singleTileMode");

		jAtlas = new J('<div class="wrapper"/>');
		jAtlas.appendTo(jPicker);

		jCursor = new J('<div class="cursorsWrapper"/>');
		jCursor.prependTo(jAtlas);

		jSelection = new J('<div class="selectionsWrapper"/>');
		jSelection.prependTo(jAtlas);

		var jImg = new J( tilesetDef.createAtlasHtmlImage() );
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

		loadScrollPos();
		renderSelection();
	}

	function set_singleSelectedTileId(v) {
		singleSelectedTileId = v;
		renderSelection();
		return singleSelectedTileId;
	}

	public dynamic function onSingleTileSelect(tileId:Int) {}

	function loadScrollPos() {
		var mem = SCROLL_MEMORY.get(tilesetDef.uid);
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
		SCROLL_MEMORY.set(tilesetDef.uid, { x:scrollX, y:scrollY, zoom:zoom });
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
		jSelection.empty();

		if( singleTileMode ) {
			if( singleSelectedTileId!=null )
				jSelection.append( createCursor({ mode:Stamp, ids:[singleSelectedTileId] },"selection") );
		}
		else
			jSelection.append( createCursor(tool.getSelectedValue(),"selection") );
	}

	function createCursor(sel:led.LedTypes.TilesetSelection, ?subClass:String, ?cWid:Int, ?cHei:Int) {
		var wrapper = new J("<div/>");
		var idsMap = new Map();
		for(tileId in sel.ids)
			idsMap.set(tileId,true);
		inline function hasCursorAt(cx:Int,cy:Int) {
			return idsMap.exists( tilesetDef.getTileId(cx,cy) );
		}

		var showIndividuals = sel.mode==Random;

		for(tileId in sel.ids) {
			var x = tilesetDef.getTileSourceX(tileId);
			var y = tilesetDef.getTileSourceY(tileId);
			var cx = tilesetDef.getTileCx(tileId);
			var cy = tilesetDef.getTileCy(tileId);

			var e = new J('<div class="tileCursor"/>');
			e.appendTo(wrapper);
			if( subClass!=null )
				e.addClass(subClass);

			if( showIndividuals )
				e.addClass("randomMode");
			else {
				e.addClass("stampMode");
				if( !hasCursorAt(cx-1,cy) ) e.addClass("left");
				if( !hasCursorAt(cx+1,cy) ) e.addClass("right");
				if( !hasCursorAt(cx,cy-1) ) e.addClass("top");
				if( !hasCursorAt(cx,cy+1) ) e.addClass("bottom");
			}

			e.css("left", x+"px");
			e.css("top", y+"px");
			var grid = tilesetDef.tileGridSize;
			e.css("width", ( cWid!=null ? cWid*grid : tilesetDef.tileGridSize )+"px");
			e.css("height", ( cHei!=null ? cHei*grid : tilesetDef.tileGridSize )+"px");
		}

		return wrapper;
	}



	var _lastRect = null;
	function updateCursor(pageX:Float, pageY:Float, force=false) {
		if( isScrolling() || Editor.ME.isKeyDown(K.SPACE) ) {
			jCursor.hide();
			return;
		}

		var r = getCursorRect(pageX, pageY);

		// Avoid re-render if it's the same rect
		if( !force && _lastRect!=null && r.cx==_lastRect.cx && r.cy==_lastRect.cy && r.wid==_lastRect.wid && r.hei==_lastRect.hei )
			return;

		var tileId = tilesetDef.getTileId(r.cx,r.cy);
		jCursor.empty();
		jCursor.show();

		if( singleTileMode ) {
			var c = createCursor({ mode:Stamp, ids:[tileId] }, null, r.wid, r.hei);
			c.appendTo(jCursor);
		}
		else {
			var saved = tilesetDef.getSavedSelectionFor(tileId);
			if( saved==null || dragStart!=null ) {
				var c = createCursor({ mode:tool.getMode(), ids:[tileId] }, dragStart!=null && dragStart.bt==2?"remove":null, r.wid, r.hei);
				c.appendTo(jCursor);
			}
			else {
				// Saved-selection rollover
				jCursor.append( createCursor(saved) );
			}
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
		return dragStart!=null && ( dragStart.bt==1 || Editor.ME.isKeyDown(K.SPACE) );
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
			var addToSelection = dragStart.bt!=2;
			if( r.wid==1 && r.hei==1 ) {
				if( Editor.ME.isCtrlDown() && isSelected(r.cx, r.cy) )
					addToSelection = false;
				applySelection([ tilesetDef.getTileId(r.cx,r.cy) ], addToSelection);
			}
			else {
				if( Editor.ME.isCtrlDown() && isSelected(r.cx, r.cy) )
					addToSelection = false;

				var tileIds = [];
				for(cx in r.cx...r.cx+r.wid)
				for(cy in r.cy...r.cy+r.hei)
					tileIds.push( tilesetDef.getTileId(cx,cy) );
				applySelection(tileIds, addToSelection);
			}
		}

		dragStart = null;
		updateCursor(ev.pageX, ev.pageY, true);
	}

	function isSelected(tcx,tcy) {
		if( singleTileMode )
			return false; // TODO

		for( id in tool.getSelectedValue().ids )
			if( id==tilesetDef.getTileId(tcx,tcy) )
				return true;
		return false;
	}

	function applySelection(selIds:Array<Int>, add:Bool) {
		// Auto-pick saved selection
		if( !singleTileMode && selIds.length==1 && tilesetDef.hasSavedSelectionFor(selIds[0]) && !Editor.ME.isCtrlDown() ) {
			// Check if the saved selection isn't already picked. If so, just pick the sub-tile
			var sel = tool.getSelectedValue();
			var saved = tilesetDef.getSavedSelectionFor( selIds[0] );
			var same = true;
			var i = 0;
			while( i<saved.ids.length ) {
				if( sel.ids[i]!=saved.ids[i] )
					same = false;
				i++;
			}
			if( !same ) {
				selIds = saved.ids.copy();
				tool.setMode( saved.mode );
			}
		}

		if( singleTileMode ) {
			onSingleTileSelect( selIds[0] );
		}
		else {
			var curSel = tool.getSelectedValue();
			if( add ) {
				if( !Editor.ME.isShiftDown() && !Editor.ME.isCtrlDown() ) {
					// Replace active selection with this one
					tool.selectValue({ mode:tool.getMode(), ids:selIds });
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
					tool.selectValue({ mode:tool.getMode(), ids:arr });
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
			Editor.ME.ge.emit(ToolOptionChanged);
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
		// Block context menu
		if( ev.button==2 )
			jDoc.on("contextmenu.pickerCtxCatcher", function(ev) {
				ev.preventDefault();
				jDoc.off(".pickerCtxCatcher");
			});

		if( ev.button==2 && singleTileMode )
			return;

		// Start dragging
		dragStart = {
			bt: ev.button,
			pageX: ev.pageX,
			pageY: ev.pageY,
		}

	}

	function onPickerMouseMove(ev:js.jquery.Event) {
		updateCursor(ev.pageX, ev.pageY);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var localX = pageXtoLocal(pageX);
		var localY = pageYtoLocal(pageY);

		var grid = tilesetDef.tileGridSize;
		var cx = M.iclamp( Std.int( localX / grid ), 0, tilesetDef.cWid-1 );
		var cy = M.iclamp( Std.int( localY / grid ), 0, tilesetDef.cHei-1 );

		if( dragStart==null || singleTileMode )
			return {
				cx: cx,
				cy: cy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = M.iclamp( Std.int( pageXtoLocal(dragStart.pageX) / grid ), 0, tilesetDef.cWid-1 );
			var startCy = M.iclamp( Std.int( pageYtoLocal(dragStart.pageY) / grid ), 0, tilesetDef.cHei-1 );
			return {
				cx: M.imin(cx,startCx),
				cy: M.imin(cy,startCy),
				wid: M.iabs(cx-startCx) + 1,
				hei: M.iabs(cy-startCy) + 1,
			}
		}
	}
}