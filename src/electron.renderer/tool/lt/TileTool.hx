package tool.lt;

class TileTool extends tool.LayerTool<data.DataTypes.TilesetSelection> {
	public var curTilesetDef(get,never) : Null<data.def.TilesetDef>;
	inline function get_curTilesetDef() return editor.curLayerInstance.getTilesetDef();

	public var flipX = false;
	public var flipY = false;
	var paintedCells : Map<Int,Bool> = new Map();

	public function new() {
		super();
		selectValue( getSelectedValue() );
	}

	override function getSelectionMemoryKey():Null<String> {
		return curTilesetDef==null ? super.getSelectionMemoryKey() : curTilesetDef.relPath;
	}

	override function getDefaultValue():data.DataTypes.TilesetSelection {
		if( curTilesetDef!=null && curTilesetDef.hasSavedSelectionFor(0) ) {
			var saved = curTilesetDef.getSavedSelectionFor(0);
			return { ids:saved.ids.copy(), mode:saved.mode }
		}
		else
			return { mode:Stamp, ids:[0] };
	}

	override function canEdit():Bool {
		return super.canEdit() && curTilesetDef!=null;
	}


	public function getMode() return getSelectedValue().mode;

	public function setMode(m:data.DataTypes.TileEditMode) {
		var s = getSelectedValue();
		selectValue({
			ids: s.ids.copy(),
			mode: m,
		});
	}

	public function selectedValueHasAny(ids:Array<Int>) {
		for( id in ids )
		for( sid in getSelectedValue().ids )
			if( id==sid )
				return true;
		return false;
	}

	public function selectedValuesIdentical(ids:Array<Int>) {
		if( ids.length!=getSelectedValue().ids.length )
			return false;

		var found : Bool;
		for( tid in getSelectedValue().ids ) {
			found = false;
			for( tid2 in ids )
				if( tid==tid2 ) {
					found = true;
					break;
				}
				if( !found )
					return false;
		}
		return true;
	}

	override function startUsing(ev:hxd.Event, m:Coords, ?extraParam:String) {
		paintedCells = new Map();
		super.startUsing(ev,m,extraParam);
		editor.selectionTool.clear();
	}

	inline function markAsPainted(cx,cy) paintedCells.set( curLayerInstance.coordId(cx,cy), true );
	inline function hasAlreadyPaintedAt(cx,cy) return paintedCells.exists( curLayerInstance.coordId(cx,cy) );

	public function isRandomMode() return getSelectedValue().mode==Random;
	public function isPaintingSingleTile() return getSelectedValue().ids.length==1;

	override function useAtInterpolatedGrid(cx:Int, cy:Int):Bool {
		super.useAtInterpolatedGrid(cx, cy);

		switch curMode {
			case null:

			case Add:
				if( drawSelectionAt(cx, cy) )
					return true;

			case Remove:
				if( removeSelectedTileAt(cx, cy) )
					return true;
		}

		return false;
	}

	override function useFloodfillAt(m:Coords):Bool {
		var topTile = curLayerInstance.getTopMostGridTile(m.cx, m.cy);
		var initialTileId : Null<Int> = topTile!=null ? topTile.tileId : null;
		var flips = M.makeBitsFromBools(flipX, flipY);

		return _floodFillImpl(
			m,
			function(cx,cy) {
				if( initialTileId==null )
					return curLayerInstance.hasAnyGridTile(cx,cy);
				else
					return !curLayerInstance.hasSpecificGridTile(cx,cy, initialTileId);
			},
			function(cx,cy,v) {
				switch curMode {
					case Add:
						switch v.mode {
							case Stamp: // Painting is done at the end, when the filled area is known

							case Random:
								var id = v.ids[ Std.random(v.ids.length) ];
								curLayerInstance.addGridTile( cx,cy, id, flips, settings.v.tileStacking && !curTilesetDef.isTileOpaque(id) );
						}

					case Remove:
						curLayerInstance.removeAllGridTiles(cx,cy, true);

					case _:
				}
			},
			function(left,right,top,bottom,pts) {
				if( getMode()==Stamp && curMode==Add ) {
					var mask = new Map();
					for(pt in pts)
						mask.set( curLayerInstance.coordId(pt.cx,pt.cy), true );
					drawSelectionInRectangle(left,top, right-left+1, bottom-top+1, mask);
				}
			}
		);
	}

	override function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(m, left, right, top, bottom);

		if( curMode==Add && !isRandomMode() )
			return drawSelectionInRectangle(left,top, right-left+1, bottom-top+1);

		var anyChange = false;
		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null:
				case Add:
					if( drawSelectionAt(cx,cy) ) // random mode only
						anyChange = true;

				case Remove:
					// Erase rectangle
					editor.curLevelTimeline.markGridChange(curLayerInstance, cx, cy);
					if( settings.v.tileStacking ) {
						if( editor.curLayerInstance.removeTopMostGridTile(cx,cy, true) )
							anyChange = true;
					}
					else {
						if( editor.curLayerInstance.removeAllGridTiles(cx,cy, true) )
							anyChange = true;
					}
			}
		}

		return anyChange;
	}


	function drawSelectionInRectangle(cx:Int, cy:Int, wid:Int, hei:Int, ?onlyCoordsMask:Map<Int,Bool>) {
		var anyChange = false;
		var flips = M.makeBitsFromBools(flipX, flipY);
		var sel = getSelectedValue();
		var selMap = new Map();

		var selLeft = Const.INFINITE;
		var selTop = Const.INFINITE;
		var selRight = -Const.INFINITE;
		var selBottom = -Const.INFINITE;

		for(tid in sel.ids) {
			selMap.set(tid,true);
			selLeft = M.imin(selLeft, curTilesetDef.getTileCx(tid));
			selRight = M.imax(selRight, curTilesetDef.getTileCx(tid));
			selTop = M.imin(selTop, curTilesetDef.getTileCy(tid));
			selBottom = M.imax(selBottom, curTilesetDef.getTileCy(tid));
		}

		var selWid = selRight-selLeft+1;
		var selHei = selBottom-selTop+1;
		var curX = cx;
		var curY = cy;
		var gridDiffScale = M.imax(1, M.round( curTilesetDef.tileGridSize / curLayerInstance.def.gridSize ) );
		for( dx in 0...wid )
		for( dy in 0...hei ) {
			if( dx%gridDiffScale!=0 || dy%gridDiffScale!=0 )
				continue;

			var x = cx+dx;
			var y = cy+dy;

			var tid = curTilesetDef.getTileId(
				selLeft + Std.int(dx/gridDiffScale)%selWid,
				selTop + Std.int(dy/gridDiffScale)%selHei
			);

			if( onlyCoordsMask==null || onlyCoordsMask.exists(curLayerInstance.coordId(x,y)) )
			if( curLayerInstance.isValid(x,y) && selMap.exists(tid) ) {
				curLayerInstance.addGridTile(x,y, tid, flips, settings.v.tileStacking && !curTilesetDef.isTileOpaque(tid));
				editor.curLevelTimeline.markGridChange(curLayerInstance, x, y);
				anyChange = true;
			}
		}

		return anyChange;
	}

	function drawSelectionAt(cx:Int, cy:Int) {
		var anyChange = false;
		var sel = getSelectedValue();
		var flips = M.makeBitsFromBools(flipX, flipY);
		var li = curLayerInstance;

		if( isRandomMode() ) {
			// Single random tile
			var tid = sel.ids[Std.random(sel.ids.length)];
			if( li.isValid(cx,cy) && !hasAlreadyPaintedAt(cx,cy) ) {
				li.addGridTile(cx,cy, tid, flips, settings.v.tileStacking && !curTilesetDef.isTileOpaque(tid));
				if( settings.v.tileStacking )
					markAsPainted(cx,cy);
				anyChange = true;
			}
		}
		else {
			// Stamp
			var left = Const.INFINITE;
			var right = 0;
			var top = Const.INFINITE;
			var bottom = 0;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				right = M.imax(right, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
				bottom = M.imax(bottom, curTilesetDef.getTileCy(tid));
			}

			var gridDiffScale = M.imax(1, M.round( curTilesetDef.tileGridSize / li.def.gridSize ) );
			for(tid in sel.ids) {
				var tdCx = curTilesetDef.getTileCx(tid);
				var tdCy = curTilesetDef.getTileCy(tid);
				var tcx = cx + ( flipX ? right-tdCx : tdCx-left ) * gridDiffScale;
				var tcy = cy + ( flipY ? bottom-tdCy : tdCy-top ) * gridDiffScale;
				if( li.isValid(tcx,tcy) && !hasAlreadyPaintedAt(tcx,tcy	) ) {
					li.addGridTile(tcx,tcy, tid, flips, settings.v.tileStacking && !curTilesetDef.isTileOpaque(tid));
					if( settings.v.tileStacking )
						markAsPainted(tcx,tcy);
					editor.curLevelTimeline.markGridChange(li, tcx, tcy);
					anyChange = true;
				}
			}
		}
		return anyChange;
	}


	function removeSelectedTileAt(cx:Int, cy:Int) {
		var sel = getSelectedValue();

		var anyChange = false;
		if( isRandomMode() || isPaintingSingleTile() ) {
			// Remove tiles one-by-one
			if( !hasAlreadyPaintedAt(cx,cy) ) {
				if( settings.v.tileStacking ) {
					if( editor.curLayerInstance.removeTopMostGridTile(cx,cy,true) ) {
						markAsPainted(cx,cy);
						anyChange = true;
					}
				}
				else {
					if( editor.curLayerInstance.removeAllGridTiles(cx,cy,true) )
						anyChange = true;
				}
			}
		}
		else {
			// Stamp erasing
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			var gridDiffScale = M.imax(1, M.round( curTilesetDef.tileGridSize / curLayerInstance.def.gridSize ) );
			for(tid in sel.ids) {
				var tcx = cx + ( curTilesetDef.getTileCx(tid) - left ) * gridDiffScale;
				var tcy = cy + ( curTilesetDef.getTileCy(tid) - top ) * gridDiffScale;
				if( !hasAlreadyPaintedAt(tcx,tcy) ) {
					if( editor.curLayerInstance.removeAllGridTiles(tcx,tcy,true) ) {
						editor.curLevelTimeline.markGridChange(curLayerInstance, tcx, tcy);
						anyChange = true;
					}
				}
			}
		}

		return anyChange;
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev,m);

		if( curTilesetDef==null || !curTilesetDef.isAtlasLoaded() ) {
			editor.cursor.set(Forbidden);
			ev.cancel = true;
			return;
		}

		if( isRunning() && rectangle ) {
			var r = Rect.fromCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei) );
			ev.cancel = true;
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) ) {
			var sel = getSelectedValue();
			var flips = M.makeBitsFromBools(flipX, flipY);
			if( isRandomMode() )
				editor.cursor.set(
					Tiles(curLayerInstance, [ sel.ids[Std.random(sel.ids.length)] ], m.cx, m.cy, flips)
					// sel.ids.length>1 ? "R" : null
				);
			else
				editor.cursor.set( Tiles(curLayerInstance, sel.ids, m.cx, m.cy, flips) );

			ev.cancel = true;
		}
	}

	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.TilePalette(this);
	}

	override function initToolOptions() {
		super.initToolOptions();

		if( project.defs.tilesets.length==0 )
			return;

		var curTd = curLayerInstance.getTilesetDef();
		var layerIsEmpty = curLayerInstance.isEmpty();

		// List tilesets
		var jTilesets = new J('<select/>');
		jTilesets.appendTo(jOptions);
		for(td in project.defs.tilesets) {
			var jOpt = new J('<option/>');
			jOpt.appendTo(jTilesets);
			jOpt.attr("value", td.uid);
			jOpt.text(td.identifier);

			if( td.uid==curLayerInstance.getDefaultTilesetUid() )
				jOpt.append(" (default)");

			// Mark as incompatible
			if( curTd!=null && td.pxWid!=curTd.pxWid && !layerIsEmpty ) {
				jOpt.addClass("bad");
				jOpt.append(' (INCOMPATIBLE SIZE!)');
			}
		}
		jTilesets.val( curLayerInstance.getTilesetUid() );

		// Pick tileset
		jTilesets.change( (_)->{
			function _apply(canUndo:Bool) {
				if( canUndo )
					new ui.LastChance(L.t._("Changed layer tileset"), project);
				curLayerInstance.setOverrideTileset( Std.parseInt( jTilesets.val() ) );
				editor.ge.emit( ToolOptionChanged );
				editor.ge.emit( LayerInstanceChangedGlobally(curLayerInstance) );
			}
			var isBad = jTilesets.find(":selected").hasClass("bad");
			if( isBad )
				new ui.modal.dialog.Confirm(jTilesets, L.t._("Warning: using this tileset in this layer will mess any existing tiles here."), true, _apply.bind(true), initToolOptions);
			else
				_apply(false);
		});
	}

	public function saveSelection() {
		curTilesetDef.saveSelection( getSelectedValue() );
		editor.ge.emit( TilesetSelectionSaved(curTilesetDef) );
		N.msg("Saved selection");
	}

	override function onAppCommand(cmd:AppCommand) {
		super.onAppCommand(cmd);

		switch cmd {
			case C_FlipX:
				flipX = !flipX;
				N.quick("X-flip: "+L.onOff(flipX));
				customCursor(new hxd.Event(EMove), lastMouse);

			case C_FlipY:
				flipY = !flipY;
				N.quick("Y-flip: "+L.onOff(flipY));
				customCursor(new hxd.Event(EMove), lastMouse);

			case C_ToggleTileRandomMode:
				setMode( isRandomMode() ? Stamp : Random );
				ui.Notification.quick((isRandomMode()?"Random":"Stamp")+" mode");
				editor.ge.emit(ToolOptionChanged);
				palette.render();

			case C_SaveTileSelection:
				saveSelection();

			case C_LoadTileSelection:
				var saved = curTilesetDef.getSavedSelectionFor( getSelectedValue().ids[0] );
				if( saved!=null && !selectedValuesIdentical(saved.ids) ) {
					if( saved.ids.length>1 )
						N.quick( L.t._("Loaded selection of ::n:: tiles", { n:saved.ids.length }) );
					selectValue({
						ids: saved.ids.copy(),
						mode: saved.mode,
					});
					onValuePicking();
				}

			case _:
		}
	}

}
