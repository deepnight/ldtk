package ui;

class TilesetPicker {
	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return new J(js.Browser.document);
	var wrapper : js.jquery.JQuery;

	var tool : tool.TileTool;
	var zoom = 2.0;
	var cursors : js.jquery.JQuery;

	var dragStart : Null<{ x:Int, y:Int }>;

	public function new(target:js.jquery.JQuery, tool:tool.TileTool) {
		this.tool = tool;

		// Create picker elements
		wrapper = new J('<div class="tilesetPicker"/>');
		wrapper.appendTo(target);
		wrapper.css("zoom",zoom);

		cursors = new J('<div/>');
		cursors.prependTo(wrapper);

		var img = new J( tool.curTilesetDef.createAtlasHtmlImage() );
		img.appendTo(wrapper);

		// Init events
		img.mousedown( function(ev) {
			ev.preventDefault();
			onPickerMouseDown(ev);
			jDoc
				.off(".pickerEvent")
				.on("mouseup.pickerEvent", onDocMouseUp)
				.on("mousemove.pickerEvent", onDocMouseMove);
		});

		img.mousemove( onPickerMouseMove );

		renderSelection();
	}

	function renderSelection() {
		wrapper.find(".selection").remove();

		for(tileId in tool.getSelectedValue())
			wrapper.append( createCursor(tileId,"selection") );
	}


	function createCursor(tileId:Int, ?subClass:String, ?cWid:Int, ?cHei:Int) {
		var x = tool.curTilesetDef.getTileSourceX(tileId);
		var y = tool.curTilesetDef.getTileSourceY(tileId);

		var e = new J('<div class="tileCursor"/>');
		if( subClass!=null )
			e.addClass(subClass);

		e.css("left", x+"px");
		e.css("top", y+"px");
		var grid = tool.curTilesetDef.tileGridSize;
		e.css("width", ( cWid!=null ? cWid*grid : tool.curTilesetDef.tileGridSize )+"px");
		e.css("height", ( cHei!=null ? cHei*grid : tool.curTilesetDef.tileGridSize )+"px");
		return e;
	}



	var _lastRect = null;
	function updateCursor(pageX:Float, pageY:Float) {
		var r = getCursorRect(pageX, pageY);

		// Avoid re-render if it's the same rect
		if( _lastRect!=null && r.cx==_lastRect.cx && r.cy==_lastRect.cy && r.wid==_lastRect.wid && r.hei==_lastRect.hei )
			return;

		var tileId = tool.curTilesetDef.getTileId(r.cx,r.cy);
		cursors.empty();

		var saved = tool.curTilesetDef.getSavedSelectionFor(tileId);
		if( saved==null )
			cursors.append( createCursor(tileId, r.wid, r.hei) );
		else {
			// Saved-selection rollover
			for(tid in saved)
				cursors.append( createCursor(tid) );
		}

		_lastRect = r;
	}


	function onDocMouseMove(ev:js.jquery.Event) {
		updateCursor(ev.pageX, ev.pageY);
	}

	function onDocMouseUp(ev:js.jquery.Event) {
		jDoc.off(".pickerEvent");

		if( dragStart!=null ) {
			// Apply selection
			var r = getCursorRect(ev.pageX, ev.pageY);
			if( r.wid==1 && r.hei==1 )
				onSelect([ tool.curTilesetDef.getTileId(r.cx,r.cy) ]);
			else {
				var tileIds = [];
				for(cx in r.cx...r.cx+r.wid)
				for(cy in r.cy...r.cy+r.hei)
					tileIds.push( tool.curTilesetDef.getTileId(cx,cy) );
				onSelect(tileIds);
			}
		}

		dragStart = null;
	}

	function onSelect(sel:Array<Int>) {
		// Auto-pick saved selection
		if( sel.length==1 && tool.curTilesetDef.hasSavedSelectionFor(sel[0]) ) {
			// Check if the saved selection isn't already picked. If so, just pick the sub-tile
			var cur = tool.getSelectedValue();
			var saved = tool.curTilesetDef.getSavedSelectionFor( sel[0] ).copy();
			var same = true;
			var i = 0;
			while( i<saved.length ) {
				if( cur[i]!=saved[i] )
					same = false;
				i++;
			}
			if( !same )
				sel = saved;
		}

		var cur = tool.getSelectedValue();
		if( !Client.ME.isShiftDown() && !Client.ME.isCtrlDown() )
			tool.selectValue(sel);
		else {
			// Add selection
			var idMap = new Map();
			for(tid in tool.getSelectedValue())
				idMap.set(tid,true);
			for(tid in sel)
				idMap.set(tid,true);

			var arr = [];
			for(tid in idMap.keys())
				arr.push(tid);
			tool.selectValue(arr);
		}
	}


	function onPickerMouseDown(ev:js.jquery.Event) {
		dragStart = {
			x: Std.int( ev.offsetX / zoom ),
			y: Std.int( ev.offsetY / zoom ),
		}
	}

	function onPickerMouseMove(ev:js.jquery.Event) {
		if( dragStart==null )
			updateCursor(ev.pageX, ev.pageY);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var curX = pageX - wrapper.offset().left * zoom;
		var curY = pageY - wrapper.offset().top * zoom;

		var grid = tool.curTilesetDef.tileGridSize;
		var curCx = Std.int( curX / grid / zoom );
		var curCy = Std.int( curY / grid / zoom );

		if( dragStart==null )
			return {
				cx: curCx,
				cy: curCy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = Std.int(dragStart.x/grid);
			var startCy = Std.int(dragStart.y/grid);
			return {
				cx: M.imin(curCx,startCx),
				cy: M.imin(curCy,startCy),
				wid: M.iabs(curCx-startCx) + 1,
				hei: M.iabs(curCy-startCy) + 1,
			}
		}
	}
}