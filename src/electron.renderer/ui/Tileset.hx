package ui;

class Tileset {
	static var SCROLL_MEMORY : Map<String, { x:Float, y:Float, zoom:Float }> = new Map();

	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return new J(js.Browser.document);

	var tilesetDef : data.def.TilesetDef;

	var jWrapper : js.jquery.JQuery;
	var jTilesetWrapper : js.jquery.JQuery;
	var jAtlas : js.jquery.JQuery;
	var jCursor : js.jquery.JQuery;
	var jSelection : js.jquery.JQuery;
	var jCanvas : js.jquery.JQuery;
	var jInfos : js.jquery.JQuery;

	var canvas(get,never) : js.html.CanvasElement;
		inline function get_canvas() return cast jCanvas.get(0);

	var zoom(default,set) : Float;
	var dragStart : Null<{ bt:Int, pageX:Float, pageY:Float }>;
	var scrollX(default,set) : Float;
	var scrollY(default,set) : Float;
	var tx : Null<Float>;
	var ty : Null<Float>;
	var mouseOver = false;
	public var useSavedSelections = true;

	var saveUiState : Bool;
	var viewFitted : Bool;

	public var displayWid(get,never) : Float;
		inline function get_displayWid() return tilesetDef.pxWid*zoom;

	public var displayHei(get,never) : Float;
		inline function get_displayHei() return tilesetDef.pxHei*zoom;

	public var right(get,never) : Float;
		inline function get_right() return scrollX+tilesetDef.pxWid*zoom;

	var selectMode : TilesetSelectionMode;
	var _internalSelectedIds : Array<Int> = [];


	public function new(jParent:js.jquery.JQuery, td:data.def.TilesetDef, mode:TilesetSelectionMode=None, saveUiState=false) {
		tilesetDef = td;
		selectMode = mode;

		// Init viewFitted flag
		this.saveUiState = saveUiState;
		if( !saveUiState || !App.ME.settings.hasUiState(getUiStateId("fit"), Editor.ME.project) )
			viewFitted = false;
		else
			viewFitted = App.ME.settings.getUiStateBool(getUiStateId("fit"), Editor.ME.project);

		// Create picker elements
		jWrapper = new J('<div class="tileset"/>');
		jWrapper.appendTo(jParent);

		jTilesetWrapper = new J('<div class="tilesetWrapper"/>');
		jTilesetWrapper.appendTo(jWrapper);

		jAtlas = new J('<div class="wrapper"/>');
		jAtlas.appendTo(jTilesetWrapper);

		jCursor = new J('<div class="cursorsWrapper"/>');
		jCursor.prependTo(jAtlas);

		jSelection = new J('<div class="selectionsWrapper"/>');
		jSelection.prependTo(jAtlas);

		jCanvas = new J('<canvas/>');
		jCanvas.attr("width",tilesetDef.pxWid+"px");
		jCanvas.attr("height",tilesetDef.pxHei+"px");
		renderAtlas();
		jCanvas.appendTo(jAtlas);

		jInfos = new J('<div class="selectionInfos"/>');
		jInfos.appendTo(jWrapper);

		// Init events
		jTilesetWrapper.mousedown( function(ev) {
			ev.preventDefault();
			onPickerMouseDown(ev);
			jDoc
				.off(".pickerDragEvent")
				.on("mouseup.pickerDragEvent", onDocMouseUp)
				.on("mousemove.pickerDragEvent", onDocMouseMove);
		});

		jTilesetWrapper.get(0).onwheel = onPickerMouseWheel;
		jTilesetWrapper.mousemove( onPickerMouseMove );
		jTilesetWrapper.mouseleave( onPickerMouseLeave );

		setSelectionMode(selectMode); // force class update
		loadScrollPos();
		renderSelection();
		if( viewFitted )
			fitView();
	}


	inline function getUiStateId(subId:String) : Settings.UiState {
		return cast "tileset_"+tilesetDef.uid+"_"+subId;
	}

	public inline function isViewFitted() return viewFitted;
	public inline function setViewFit(v:Bool) {
		viewFitted = v;
		if( viewFitted ) {
			if( saveUiState )
				App.ME.settings.setUiStateBool(getUiStateId("fit"), viewFitted, Editor.ME.project);
			fitView();
		}
		else if( saveUiState )
			App.ME.settings.deleteUiState(getUiStateId("fit"), Editor.ME.project);
	}


	public inline function fitsHorizontally() {
		return displayWid<=jTilesetWrapper.outerWidth();
	}

	public inline function fitsVertically() {
		return displayHei<=jTilesetWrapper.outerHeight();
	}

	public function fitView() {
		zoom = M.fmin(
			jTilesetWrapper.outerWidth() / tilesetDef.pxWid,
			jTilesetWrapper.outerHeight() / tilesetDef.pxHei
		);
		scrollX = 0;
		tx = null;
		scrollY = 0;
		ty = null;
	}

	public function setSelectionMode(m:TilesetSelectionMode) {
		if( selectMode!=null )
			jWrapper.removeClass( selectMode.getName() );
		jWrapper.addClass(m.getName());
		selectMode = m;
	}

	public static function clearScrollMemory() {
		SCROLL_MEMORY = new Map();
	}

	public function renderAtlas() {
		tilesetDef.drawAtlasToCanvas(jCanvas);
	}

	function customTileRender(ctx:js.html.CanvasRenderingContext2D, x:Int, y:Int, tileId:Int) {
		return false;
	}

	public function renderGrid() {
		var ctx = canvas.getContext2d();
		ctx.lineWidth = M.fmax( 1, Std.int( tilesetDef.tileGridSize / 16 ) );
		var strokeOffset = ctx.lineWidth*0.5; // draw in the middle of the pixel to avoid blur

		for(tileId in 0...tilesetDef.cWid*tilesetDef.cHei) {
			var x = tilesetDef.getTileSourceX(tileId);
			var y = tilesetDef.getTileSourceY(tileId);

			// Outline
			ctx.beginPath();
			ctx.rect(
				x + strokeOffset,
				y + strokeOffset,
				tilesetDef.tileGridSize - strokeOffset*2,
				tilesetDef.tileGridSize - strokeOffset*2
			);

			// Outline color
			var c = tilesetDef.getAverageTileColor(tileId);
			var a = C.getA(c)>0 ? 0.5 : 0;
			ctx.strokeStyle =
				C.intToHexRGBA( C.toWhite( C.replaceAlphaF( tilesetDef.getAverageTileColor(tileId), a ), 0.2 ) );

			ctx.stroke();
		}
	}

	function resetScroll() {
		tx = ty = null;
		scrollX = 0;
		scrollY = 0;
		zoom = 3;
		SCROLL_MEMORY.remove( tilesetDef.relPath );
	}

	public function getSelectedRect() : Null<ldtk.Json.TilesetRect> {
		return switch selectMode {
			case None: null;
			case OneTile, OneTileAndClose: null;
			case MultipleIndividuals: null;
			case TileRect, TileRectAndClose: tilesetDef.getTileRectFromTileIds( getSelectedTileIds() );
		}
	}

	public function getSelectedTileIds() {
		return switch selectMode {
			case None: [];
			case MultipleIndividuals: _internalSelectedIds;
			case OneTile, OneTileAndClose: _internalSelectedIds;
			case TileRect, TileRectAndClose: _internalSelectedIds;
		}
	}

	public function setSelectedTileIds(tileIds:Array<Int>) {
		// switch selectMode {
		// 	case None: throw "unexpected";
		// 	case PickAndClose, Free, RectOnly, PickSingle: _internalSelectedIds = tileIds;
		// }
		_internalSelectedIds = tileIds;
		renderSelection();
	}

	public function setSelectedRect(r:ldtk.Json.TilesetRect) {
		setSelectedTileIds( tilesetDef.getTileIdsFromRect(r) );
	}

	public dynamic function onSelectAnything() {}
	public dynamic function onClickOutOfBounds() {}

	function loadScrollPos() {
		if( viewFitted )
			fitView();
		else {
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
	}

	function saveScrollPos() {
		SCROLL_MEMORY.set(tilesetDef.relPath, { x:scrollX, y:scrollY, zoom:zoom });
	}

	function set_zoom(v) {
		if( viewFitted )
			zoom = v;
		else
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

	inline function pageToLocalX(v:Float) return M.round( ( v - jWrapper.offset().left ) / zoom + scrollX );
	inline function pageToLocalY(v:Float) return M.round( ( v - jWrapper.offset().top ) / zoom + scrollY );

	inline function pageToCx(v:Float, clamp=true) : Int {
		var v = M.floor( (pageToLocalX(v)-tilesetDef.padding) / ( tilesetDef.tileGridSize+tilesetDef.spacing ) );
		return clamp ? M.iclamp(v,0,tilesetDef.cWid-1) : v;
	}

	inline function pageToCy(v:Float, clamp=true) : Int {
		var v = M.floor( (pageToLocalY(v)-tilesetDef.padding) / ( tilesetDef.tileGridSize+tilesetDef.spacing ) );
		return clamp ? M.iclamp(v,0,tilesetDef.cHei-1) : v;
	}

	public inline function get2dContext() {
		return canvas.getContext2d();
	}

	public function renderHighlightedTiles(tileIds:Array<Int>, col:dn.Col) {
		tileIds.sort( (a,b)->Reflect.compare(a,b) );
		var tileMap = new Map();
		for(tid in tileIds)
			tileMap.set(tid,true);


		var ctx = canvas.getContext2d();
		var thick = 2;
		var grid = tilesetDef.tileGridSize;
		for(tid in tileIds) {
			var x = tilesetDef.getTileSourceX(tid);
			var y = tilesetDef.getTileSourceY(tid);

			ctx.fillStyle = col.toCssRgba(0.4);
			ctx.fillRect(x,y,grid,grid);
			ctx.fillStyle = col.toHex();

			// Left border
			if( !tileMap.exists(tid-1) )
				ctx.fillRect(x-thick, y, thick, grid);

			// Right border
			if( !tileMap.exists(tid+1) )
				ctx.fillRect(x+grid, y, thick, grid);

			// Top border
			if( !tileMap.exists(tid-tilesetDef.cWid) )
				ctx.fillRect(x, y-thick, grid, thick);

			// Bottom border
			if( !tileMap.exists(tid+tilesetDef.cWid) )
				ctx.fillRect(x, y+grid, grid, thick);
		}
	}

	public function renderArrow(fx:Int, fy:Int, tx:Int, ty:Int, col:dn.Col, thickness=2) {
		var ang = Math.atan2(ty-fy, tx-fx);
		var ctx = canvas.getContext2d();

		// Arrow path
		ctx.beginPath();
		ctx.moveTo(fx,fy);
		ctx.lineTo(tx,ty);

		ctx.moveTo(tx+Math.cos(ang+M.PIHALF*1.5)*6, ty+Math.sin(ang+M.PIHALF*1.5)*6);
		ctx.lineTo(tx,ty);
		ctx.lineTo(tx+Math.cos(ang-M.PIHALF*1.5)*6, ty+Math.sin(ang-M.PIHALF*1.5)*6);

		// Stroke outline
		ctx.lineWidth = thickness+1;
		ctx.lineCap = "round";
		ctx.strokeStyle = "#000000";
		ctx.stroke();

		// Stroke arrow
		ctx.lineWidth = thickness;
		ctx.strokeStyle = col.toHex();
		ctx.stroke();
	}

	function renderSelection() {
		jSelection.empty();

		switch selectMode {
			case MultipleIndividuals:
				if( getSelectedTileIds().length>0 )
					jSelection.append( createCursor({ mode:Random, ids:getSelectedTileIds() },"selection") );

			case OneTile, OneTileAndClose, TileRect, TileRectAndClose:
				if( getSelectedTileIds().length>0 )
					jSelection.append( createCursor({ mode:Stamp, ids:getSelectedTileIds() },"selection") );

			case None:
		}
	}

	public function useOldTilesetPos(old:Tileset) {
		scrollX = old.scrollX;
		scrollY = old.scrollY;
		tx = old.tx;
		ty = old.ty;
	}


	public function focusOnSelection(instant=false) {
		if( viewFitted )
			return;

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


		tx = tilesetDef.padding + cx*(tilesetDef.tileGridSize+tilesetDef.spacing) - jTilesetWrapper.outerWidth()*0.5/zoom;
		ty = tilesetDef.padding + cy*(tilesetDef.tileGridSize+tilesetDef.spacing) - jTilesetWrapper.outerHeight()*0.25/zoom;

		if( instant ) {
			scrollX = tx;
			scrollY = ty;
			tx = ty = null;
		}

		saveScrollPos();
	}

	public function focusAround(tileIds:Array<Int>, instant=false) {
		if( viewFitted )
			return;

		if( tileIds.length==0 )
			return;

		var cx = 0.;
		var cy = 0.;
		for(tid in tileIds) {
			cx += tilesetDef.getTileCx(tid);
			cy += tilesetDef.getTileCy(tid);
		}
		cx = cx/tileIds.length;
		cy = cy/tileIds.length;
		cx+=0.5;
		cy+=0.5;


		tx = tilesetDef.padding + cx*(tilesetDef.tileGridSize+tilesetDef.spacing) - jTilesetWrapper.outerWidth()*0.5/zoom;
		ty = tilesetDef.padding + cy*(tilesetDef.tileGridSize+tilesetDef.spacing) - jTilesetWrapper.outerHeight()*0.5/zoom;
		if( instant ) {
			scrollX = tx;
			scrollY = ty;
			tx = ty = null;
		}

		saveScrollPos();
	}

	function createCursor(sel:data.DataTypes.TilesetSelection, ?subClass:String, ?cWid:Int, ?cHei:Int) {
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


	function isRectangleOnly() : Bool {
		return switch selectMode {
			case None: false;
			case MultipleIndividuals: false;
			case OneTile: true;
			case OneTileAndClose: true;
			case TileRect: true;
			case TileRectAndClose: true;
		}
	}


	public inline function setCursorCss(?cursorId:String) {
		if( cursorId==null && jTilesetWrapper.attr("cursor")!=null )
			jTilesetWrapper.removeAttr("cursor");
		else if( cursorId!=null && jTilesetWrapper.attr("cursor")!=cursorId )
			jTilesetWrapper.attr("cursor", cursorId);
	}


	public function clearCursor() {
		jCursor.hide();
	}


	var _lastRect = null;
	function updateCursor(pageX:Float, pageY:Float, force=false) {
		if( selectMode==None || isScrolling() || App.ME.isKeyDown(K.SPACE) || !mouseOver || !inTilesetBounds(pageX,pageY,1) ) {
			jCursor.hide();
			setCursorCss("pan");
			return;
		}

		setCursorCss("pick");
		if( updateCursorCustom(pageX,pageY, dragStart!=null) ) {
			jCursor.hide();
			return;
		}

		var r = getCursorRect(pageX, pageY);
		jCursor.show();

		// Avoid re-render if it's the same rect
		if( !force && _lastRect!=null && r.cx==_lastRect.cx && r.cy==_lastRect.cy && r.wid==_lastRect.wid && r.hei==_lastRect.hei )
			return;

		var tileId = tilesetDef.getTileId(r.cx,r.cy);
		jCursor.empty();

		// Infos
		jInfos.empty().text("#"+tileId);

		var defaultClass = dragStart==null ? "mouseOver" : null;

		if( selectMode==OneTileAndClose ) {
			var c = createCursor({ mode:Stamp, ids:[tileId] }, defaultClass, r.wid, r.hei);
			c.appendTo(jCursor);
		}
		else {
			var saved = useSavedSelections ? tilesetDef.getSavedSelectionFor(tileId) : null;
			if( saved!=null && dragStart==null ) {
				// Saved-selection rollover
				jCursor.append( createCursor(saved) );
			}
			else {
				// Normal
				var c = createCursor(
					{ mode: isRectangleOnly() ? Stamp : Random,  ids:[tileId] },
					dragStart!=null && dragStart.bt==2?"remove":defaultClass,
					r.wid,
					r.hei
				);
				c.appendTo(jCursor);
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
		return dragStart!=null && ( selectMode==None || dragStart.bt==1 || App.ME.isKeyDown(K.SPACE) );
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
				if( App.ME.isCtrlCmdDown() && isSelected(r.cx, r.cy) )
					addToSelection = false;
				modifySelection([ tilesetDef.getTileId(r.cx,r.cy) ], addToSelection);
			}
			else {
				if( App.ME.isCtrlCmdDown() && isSelected(r.cx, r.cy) )
					addToSelection = false;

				var tileIds = [];
				for(cx in r.cx...r.cx+r.wid)
				for(cy in r.cy...r.cy+r.hei)
					tileIds.push( tilesetDef.getTileId(cx,cy) );
				modifySelection(tileIds, addToSelection);
			}
		}

		dragStart = null;
		updateCursor(ev.pageX, ev.pageY, true);
	}

	function isSelected(tcx,tcy) {
		if( selectMode==OneTileAndClose )
			return false;

		for( id in getSelectedTileIds() )
			if( id==tilesetDef.getTileId(tcx,tcy) )
				return true;

		return false;
	}

	function isClosed() {
		return jWrapper.closest("body").length==0;
	}

	function modifySelection(selIds:Array<Int>, add:Bool) {
		if( isClosed() )
			return;

		switch selectMode {
			case None:

			case OneTileAndClose, TileRectAndClose:
				setSelectedTileIds(selIds);

			case MultipleIndividuals, OneTile, TileRect:
				if( add ) {
					if( isRectangleOnly() || !App.ME.isShiftDown() && !App.ME.isCtrlCmdDown() ) {
						// Replace active selection with this one
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

						setSelectedTileIds(arr);
					}
				}
				else if( !isRectangleOnly() ) {
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
				Editor.ME.ge.emit(ToolValueSelected);

			// case PaintId( valueGetter, paint ):
			// 	if( valueGetter()!=null )
			// 		for(tid in selIds)
			// 			paint(tid, valueGetter(), add);
		}

		renderSelection();
		onSelect(selIds, add);
		onSelectAnything();
	}

	function onSelect(tileIds:Array<Int>, added:Bool) {}


	function onPickerMouseWheel(ev:js.html.WheelEvent) {

		if( ev.deltaY!=0 ) {
			ev.preventDefault();
			if( viewFitted )
				return;

			var oldLocalX = pageToLocalX(ev.pageX);
			var oldLocalY = pageToLocalY(ev.pageY);

			zoom += -ev.deltaY*0.001 * zoom;

			var newLocalX = pageToLocalX(ev.pageX);
			var newLocalY = pageToLocalY(ev.pageY);
			scrollX += ( oldLocalX - newLocalX );
			scrollY += ( oldLocalY - newLocalY );

			tx = ty = null;
		}
	}

	function inTilesetBounds(pageX:Float, pageY:Float, pad=0) {
		var cx = pageToCx(pageX, false);
		var cy = pageToCy(pageY, false);
		return cx>=-pad && cx<tilesetDef.cWid+pad && cy>=-pad && cy<tilesetDef.cHei+pad;
	}

	function onPickerMouseDown(ev:js.jquery.Event) {
		if( ev.button==0 && !inTilesetBounds(ev.pageX, ev.pageY) ) {
			onClickOutOfBounds();
			return;
		}

		var tid = tilesetDef.getTileId( pageToCx(ev.pageX), pageToCy(ev.pageY) );
		if( onMouseDownCustom(ev,tid) )
			return;

		if( ev.button==2 && selectMode==OneTileAndClose )
			return;

		if( ev.button==2 && ( selectMode==TileRect || selectMode==TileRectAndClose ) )
			setSelectedTileIds([]);

		if( ev.button==1 && viewFitted )
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
		var cx = pageToCx(ev.pageX);
		var cy = pageToCy(ev.pageY);
		onMouseMoveCustom( ev, tilesetDef.getTileId(cx,cy) );
	}

	public dynamic function onMouseDownCustom(event:js.jquery.Event, tileId:Int) : Bool {
		return false;
	}
	public dynamic function onMouseMoveCustom(event:js.jquery.Event, tileId:Int) {}
	public dynamic function onMouseLeaveCustom(event:js.jquery.Event) {}
	public dynamic function updateCursorCustom(pageX:Float, pageY:Float, isDragging:Bool) {
		return false;
	}


	function onPickerMouseLeave(ev:js.jquery.Event) {
		mouseOver = false;
		updateCursor(ev.pageX, ev.pageY);
		onMouseLeaveCustom(ev);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var localX = pageToLocalX(pageX);
		var localY = pageToLocalY(pageY);
		var cx = pageToCx(pageX);
		var cy = pageToCy(pageY);

		if( dragStart==null || selectMode==OneTile || selectMode==OneTileAndClose )
			return {
				cx: cx,
				cy: cy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = pageToCx(dragStart.pageX);
			var startCy = pageToCy(dragStart.pageY);
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
		final spd = M.fmin(1, 0.38 * App.ME.tmod);
		if( tx!=null ) {
			scrollX += (tx-scrollX) * spd;
			if( M.fabs(scrollX-tx)<=1 ) {
				scrollX = tx;
				tx = null;
			}
		}
		if( ty!=null ) {
			scrollY += (ty-scrollY) * spd;
			if( M.fabs(scrollY-ty)<=1 ) {
				scrollY = ty;
				ty = null;
			}
		}
	}
}