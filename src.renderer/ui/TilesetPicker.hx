package ui;

enum PickerMode {
	ToolPicker;
	MultiTiles;
	SingleTile;
	ViewOnly;
}

class TilesetPicker {
	static var SCROLL_MEMORY : Map<String, { x:Float, y:Float, zoom:Float }> = new Map();

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
	var tx : Null<Float>;
	var ty : Null<Float>;
	var mouseOver = false;

	public var mode : PickerMode;
	var _internalSelectedIds : Array<Int> = [];


	public function new(target:js.jquery.JQuery, td:led.def.TilesetDef, ?tool:tool.TileTool) {
		tilesetDef = td;
		this.tool = tool;

		if( tool!=null )
			mode = ToolPicker;
		else
			mode = MultiTiles;

		// Create picker elements
		jPicker = new J('<div class="tilesetPicker"/>');
		jPicker.appendTo(target);
		switch mode {
			case ToolPicker:
			case MultiTiles: jPicker.addClass("multiTilesMode");
			case SingleTile: jPicker.addClass("singleTileMode");
			case ViewOnly: jPicker.addClass("viewOnlyMode");
		}

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
		jPicker.mouseleave( onPickerMouseLeave );

		loadScrollPos();
		renderSelection();
	}

	public static function clearScrollMemory() {
		SCROLL_MEMORY = new Map();
	}

	public function renderGrid() {
		jPicker.remove(".grid");
		var jGrid = new J('<div class="grid"/>');
		jGrid.prependTo(jAtlas);

		for(cy in 0...tilesetDef.cHei)
		for(cx in 0...tilesetDef.cWid) {
			var jCell = new J('<div/>');
			var tid = tilesetDef.getTileId(cx,cy);
			jCell.offset({
				left: tilesetDef.getTileSourceX(tid),
				top: tilesetDef.getTileSourceY(tid),
			});
			jCell.css("width", (tilesetDef.tileGridSize-2)+"px");
			jCell.css("height", (tilesetDef.tileGridSize-2)+"px");
			jGrid.append(jCell);
		}
	}

	public function resetScroll() {
		tx = ty = null;
		scrollX = 0;
		scrollY = 0;
		zoom = 3;
		SCROLL_MEMORY.remove( tilesetDef.relPath );
	}

	public function getSelectedTileIds() {
		return switch mode {
			case ToolPicker:
				tool.getSelectedValue().ids;

			case MultiTiles, SingleTile:
				_internalSelectedIds;

			case ViewOnly:
				[];
		}
	}

	public function setSelectedTileIds(tileIds:Array<Int>) {
		switch mode {
			case ToolPicker:
				tool.getSelectedValue().ids = tileIds;

			case MultiTiles, SingleTile:
				_internalSelectedIds = tileIds;

			case ViewOnly:
				throw "unexpected";
		}
		renderSelection();
	}

	public dynamic function onSingleTileSelect(tileId:Int) {}

	function loadScrollPos() {
		var mem = SCROLL_MEMORY.get(tilesetDef.relPath);
		if( mem!=null ) {
			tx = ty = null;
			scrollX = mem.x;
			scrollY = mem.y;
			zoom = mem.zoom;
		}
		else
			resetScroll();
	}

	function saveScrollPos() {
		SCROLL_MEMORY.set(tilesetDef.relPath, { x:scrollX, y:scrollY, zoom:zoom });
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

		switch mode {
			case ToolPicker:
				jSelection.append( createCursor(tool.getSelectedValue(),"selection") );

			case MultiTiles, SingleTile:
				if( getSelectedTileIds().length>0 )
					jSelection.append( createCursor({ mode:Random, ids:getSelectedTileIds() },"selection") );

			case ViewOnly:
		}
	}

	public function focusOnSelection() {
		var tids = getSelectedTileIds();
		if( tids.length==0 )
			return;

		var cx = 0.;
		var cy = 0.;
		for(tid in tids) {
			cx += tilesetDef.getTileCx(tid);
			cy += tilesetDef.getTileCy(tid);
		}
		cx = cx/tids.length;
		cy = cy/tids.length;
		cx+=0.5;
		cy+=0.5;

		tx = tilesetDef.padding + cx*(tilesetDef.tileGridSize+tilesetDef.spacing) - jPicker.outerWidth()*0.5/zoom;
		ty = tilesetDef.padding + cy*(tilesetDef.tileGridSize+tilesetDef.spacing) - jPicker.outerHeight()*0.5/zoom;

		saveScrollPos();
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
			e.css("width", ( cWid!=null ? cWid*grid + (cWid-1)*tilesetDef.spacing : tilesetDef.tileGridSize )+"px");
			e.css("height", ( cHei!=null ? cHei*grid + (cHei-1)*tilesetDef.spacing: tilesetDef.tileGridSize )+"px");
		}

		return wrapper;
	}



	var _lastRect = null;
	function updateCursor(pageX:Float, pageY:Float, force=false) {
		if( mode==ViewOnly || isScrolling() || App.ME.isKeyDown(K.SPACE) || !mouseOver ) {
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

		var defaultClass = dragStart==null ? "mouseOver" : null;

		if( mode==SingleTile ) {
			var c = createCursor({ mode:Stamp, ids:[tileId] }, defaultClass, r.wid, r.hei);
			c.appendTo(jCursor);
		}
		else {
			var saved = mode==ToolPicker ? tilesetDef.getSavedSelectionFor(tileId) : null;
			if( saved==null || dragStart!=null ) {
				var c = createCursor(
					{ mode:mode==ToolPicker ? tool.getMode() : Random, ids:[tileId] },
					dragStart!=null && dragStart.bt==2?"remove":defaultClass,
					r.wid,
					r.hei
				);
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
		return dragStart!=null && ( dragStart.bt==1 || App.ME.isKeyDown(K.SPACE) );
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
				if( App.ME.isCtrlDown() && isSelected(r.cx, r.cy) )
					addToSelection = false;
				applySelection([ tilesetDef.getTileId(r.cx,r.cy) ], addToSelection);
			}
			else {
				if( App.ME.isCtrlDown() && isSelected(r.cx, r.cy) )
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
		if( mode==SingleTile )
			return false;

		for( id in getSelectedTileIds() )
			if( id==tilesetDef.getTileId(tcx,tcy) )
				return true;

		return false;
	}

	function applySelection(selIds:Array<Int>, add:Bool) {
		// Auto-pick saved selection
		if( mode==ToolPicker && selIds.length==1 && tilesetDef.hasSavedSelectionFor(selIds[0]) && !App.ME.isCtrlDown() ) {
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

		if( mode==SingleTile )
			onSingleTileSelect( selIds[0] );
		else if( mode!=ViewOnly ) {
			if( add ) {
				if( !App.ME.isShiftDown() && !App.ME.isCtrlDown() ) {
					// Replace active selection with this one
					if( mode==ToolPicker )
						tool.selectValue({ mode:tool.getMode(), ids:selIds });
					else
						setSelectedTileIds(selIds);
				}
				else {
					// Add selection (OR)
					var curSelIds = getSelectedTileIds();
					var idMap = new Map();
					for(tid in curSelIds)
						idMap.set(tid,true);
					for(tid in selIds)
						idMap.set(tid,true);

					var arr = [];
					for(tid in idMap.keys())
						arr.push(tid);

					if( mode==ToolPicker )
						tool.selectValue({ mode:tool.getMode(), ids:arr });
					else
						setSelectedTileIds(arr);
				}
			}
			else {
				// Substract selection
				var curSelIds = getSelectedTileIds();
				var remMap = new Map();
				for(tid in selIds)
					remMap.set(tid, true);

				var i = 0;
				while( i<curSelIds.length && curSelIds.length>1 )
					if( remMap.exists(curSelIds[i]) )
						curSelIds.splice(i,1);
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

			tx = ty = null;
		}
	}

	function onPickerMouseDown(ev:js.jquery.Event) {
		// Block context menu
		if( ev.button==2 )
			jDoc.on("contextmenu.pickerCtxCatcher", function(ev) {
				ev.preventDefault();
				jDoc.off(".pickerCtxCatcher");
			});

		if( ev.button==2 && mode==SingleTile )
			return;

		// Start dragging
		dragStart = {
			bt: ev.button,
			pageX: ev.pageX,
			pageY: ev.pageY,
		}

		tx = ty = null;
	}

	function onPickerMouseMove(ev:js.jquery.Event) {
		mouseOver = true;
		updateCursor(ev.pageX, ev.pageY);
	}

	function onPickerMouseLeave(ev:js.jquery.Event) {
		mouseOver = false;
		updateCursor(ev.pageX, ev.pageY);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var localX = pageXtoLocal(pageX);
		var localY = pageYtoLocal(pageY);

		var grid = tilesetDef.tileGridSize;
		var spacing = tilesetDef.spacing;
		var padding = tilesetDef.padding;
		var cx = M.iclamp( Std.int( (localX-padding) / ( grid+spacing ) ), 0, tilesetDef.cWid-1 );
		var cy = M.iclamp( Std.int( (localY-padding) / ( grid+spacing ) ), 0, tilesetDef.cHei-1 );

		if( dragStart==null || mode==SingleTile )
			return {
				cx: cx,
				cy: cy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = M.iclamp( Std.int( (pageXtoLocal(dragStart.pageX)-padding) / ( grid+spacing ) ), 0, tilesetDef.cWid-1 );
			var startCy = M.iclamp( Std.int( (pageYtoLocal(dragStart.pageY)-padding) / ( grid+spacing ) ), 0, tilesetDef.cHei-1 );
			return {
				cx: M.imin(cx,startCx),
				cy: M.imin(cy,startCy),
				wid: M.iabs(cx-startCx) + 1,
				hei: M.iabs(cy-startCy) + 1,
			}
		}
	}

	public function update() {
		// Focus scrolling animation
		if( tx!=null ) {
			var spd = 0.07;
			scrollX += (tx-scrollX) * spd;
			scrollY += (ty-scrollY) * spd;
		}
	}
}