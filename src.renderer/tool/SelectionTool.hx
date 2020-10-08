package tool;

class SelectionTool extends Tool<Int> {
	var selectionCursors : Array<ui.Cursor>; // TODO should be done by Group
	var moveStarted = false;
	var movePreview : h2d.Graphics;
	var isCopy = false;
	var group : GenericLevelElementGroup;

	public function new() {
		super();

		movePreview = new h2d.Graphics();
		editor.levelRender.root.add(movePreview, Const.DP_UI);

		group = new GenericLevelElementGroup();
		selectionCursors = [];
	}

	override function onDispose() {
		super.onDispose();
		movePreview.remove();
		group.dispose();
	}

	override function getDefaultValue() return -1; // Not actually used

	function clearCursors() {
		for(c in selectionCursors)
			c.destroy();
		selectionCursors = [];
	}

	function updateSelectionCursors() { // TODO should be done by Group
		clearCursors();
		for( ge in group.all() ) {
			var c = new ui.Cursor();
			selectionCursors.push(c);
			c.enablePermanentHighlights();
			c.set(switch ge {
				case IntGrid(li, cx, cy): GridCell(li, cx,cy);
				case Entity(li, ei): Entity(li, ei.def, ei, ei.x, ei.y);
				case Tile(li,cx,cy): Tiles(li, [li.getGridTile(cx,cy)], cx,cy);
				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					GridCell(li, pt.cx, pt.cy);
			});
		}
	}

	public function select(?elems:Array<GenericLevelElement>) {
		group.clear();
		if( elems!=null )
			for(ge in elems)
				group.add(ge);

		updateSelectionCursors();

		if( isSingle() ) {
			// Change layer
			switch group.get(0) {
				case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
					if( li!=editor.curLayerInstance )
						editor.selectLayerInstance(li);
				case null:
			}

			// Selection effect
			switch group.get(0) {
				case IntGrid(li, cx, cy):
					var v = li.getIntGrid(cx,cy);
					editor.curTool.as(tool.lt.IntGridTool).selectValue(v);
					editor.levelRender.bleepRectPx( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, li.getIntGridColorAt(cx,cy) );

				case Entity(li, ei):
					editor.curTool.as(tool.lt.EntityTool).selectValue(ei.defUid); // BUG might crash
					editor.levelRender.bleepRectPx( ei.left, ei.top, ei.def.width, ei.def.height, ei.def.color );
					ui.EntityInstanceEditor.openFor(ei);


				case Tile(li, cx, cy):
					var tid = li.getGridTile(cx,cy);

					var t = editor.curTool.as(tool.lt.TileTool);
					t.selectValue( { ids:[tid], mode:t.getMode() } ); // TODO re-support picking saved selections?

					editor.levelRender.bleepRectPx( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, 0xffcc00 );

				case PointField(li, ei, fi, arrayIdx):
					editor.curTool.as(tool.lt.EntityTool).selectValue(ei.defUid); // BUG might crash
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null)
						editor.levelRender.bleepRectCase( pt.cx, pt.cy, 1, 1, ei.def.color );
					ui.EntityInstanceEditor.openFor(ei);
			}

			editor.curTool.onValuePicking();
		}
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		for( c in selectionCursors )
			c.root.visible = !isRunning();

		// Default cursor
		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, 0xffffff) );
		}
		else if( isRunning() )
			editor.cursor.set(Moving);
		else if( isOveringSelection(m) )
			editor.cursor.set(Move);
		else if( !isRunning() ) {
			// Preview picking
			var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
			switch ge {
			case null:
				editor.cursor.set(PickNothing);

			case IntGrid(li, cx, cy):
				var id = li.getIntGridIdentifierAt(cx,cy);
				editor.cursor.set(
					GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ),
					id==null ? "#"+li.getIntGrid(cx,cy) : id
				);

			case Entity(li, ei):
				editor.cursor.set(
					Entity(li, ei.def, ei, ei.x, ei.y),
					ei.def.identifier,
					true
				);

			case Tile(li, cx,cy):
				editor.cursor.set(
					Tiles(li, [li.getGridTile(cx,cy)], cx, cy),
					"Tile "+li.getGridTile(cx,cy)
				);

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				editor.cursor.set( GridCell(li, pt.cx, pt.cy, ei.getSmartColor(false)) );
			}

			if( ge!=null )
				editor.cursor.setSystemCursor( hxd.Cursor.CustomCursor.getNativeCursor("grab") );
		}
	}

	public function isOveringSelection(m:MouseCoords) {
		if( isEmpty() )
			return false;

		for(ge in group.all()) {
			switch ge {
				case IntGrid(li, cx, cy):
					if( m.getLayerCx(li)==cx && m.getLayerCy(li)==cy )
						return true;

				case Entity(li, ei):
					if( ei.isOver(m.levelX,m.levelY) )
						return true;

				case Tile(li, cx, cy):
					if( m.getLayerCx(li)==cx && m.getLayerCy(li)==cy )
						return true;

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null && m.getLayerCx(li)==pt.cx && m.getLayerCy(li)==pt.cy )
						return true;
			}
		}
		return false;
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		isCopy = App.ME.isCtrlDown() && App.ME.isAltDown();
		moveStarted = false;
		editor.clearSpecialTool();
		movePreview.clear();

		super.startUsing(m, buttonId);

		if( buttonId==0 ) {
			if( isOveringSelection(m) ) {
				// Move existing selection
				if( group.hasMixedGridSizes() ) {
					new ui.modal.dialog.Message(L.t._("This selection can't be moved around because it contains elements from using different grid sizes."));
					stopUsing(m);
				}
			}
			else {
				// Start a new selection
				if( rectangle )
					select();
				else {
					var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
					if( ge!=null )
						select([ ge ]);
					else
						select();
				}
			}
		}
	}

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);

		if( rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			if( r.wid==1 && r.hei==1 ) {
				// Pick single value, in the end
				var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
				if( ge!=null )
					select([ ge ]);
				else
					select();
			}
			else {
				// Pick every objects under rectangle
				var r = Rect.fromMouseCoords(origin, m);
				var all = [];
				function selectAllInLayer(li:led.inst.LayerInstance) {
					if( !editor.levelRender.isLayerVisible(li) )
						return;

					for( cy in r.top...r.bottom+1 )
					for( cx in r.left...r.right+1 ) {
						// IntGrid
						if( li.def.type==IntGrid && li.hasIntGrid(cx,cy) )
							all.push( IntGrid(li,cx,cy) );

						// Tiles
						if( li.def.type==Tiles && li.hasGridTile(cx,cy) )
							all.push( Tile(li,cx,cy) );
					}

					// Entities
					if( li.def.type==Entities ) {
						for(ei in li.entityInstances) {
							if( ei.getCx(li.def)>=r.left && ei.getCx(li.def)<=r.right && ei.getCy(li.def)>=r.top && ei.getCy(li.def)<=r.bottom ) {
								all.push( Entity(li,ei) );
								// Entity points
								for(fi in ei.fieldInstances)
								for(i in 0...fi.getArrayLength())
									if( fi.def.type==F_Point ) {
										var pt = fi.getPointGrid(i);
										if( pt.cx>=r.left && pt.cx<=r.right && pt.cy>=r.top && pt.cy<=r.bottom )
											all.push( PointField(li, ei, fi, i) );
									}
							}
						}
					}
				}

				if( editor.levelRender.enhanceActiveLayer )
					selectAllInLayer( editor.curLayerInstance );
				else {
					for(li in editor.curLevel.layerInstances)
						selectAllInLayer(li);
				}
				select(all);
			}
		}
		movePreview.clear();
		group.hideGhost();
	}

	public inline function get() return getSelectedValue();
	public function clear() {
		if( !isEmpty() )
			select();
	}
	public inline function any() return group.length()>0;
	public inline function isEmpty() return group.length()==0;
	public inline function isSingle() return group.length()==1;


	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		// Start moving elements only after a small elapsed mouse distance
		if( isRunning() && button==0 && !moveStarted && M.dist(origin.pageX, origin.pageY, m.pageX, m.pageY) >= 10*Const.SCALE ) {
			moveStarted = true;

			// Copy selection
			// if( any() && isCopy ) {
			// 	var copy = duplicateSelection();
			// 	if( copy!=null )
			// 		selectValue(copy);
			// }
		}

		// Render "move arrow" preview
		if( any() && isRunning() && moveStarted ) { // TODO should be done in Group?
			switch group.get(0) {
				case IntGrid(_), Tile(_):
					movePreview.clear();
					var fx = (origin.cx+0.5) * editor.curLayerDef.gridSize;
					var fy = (origin.cy+0.5) * editor.curLayerDef.gridSize;
					var tx = (m.cx+0.5) * editor.curLayerDef.gridSize;
					var ty = (m.cy+0.5) * editor.curLayerDef.gridSize;
					var a = Math.atan2(ty-fy, tx-fx);
					var arrow = 10;
					movePreview.lineStyle(1, 0xffffff, 1);
					movePreview.moveTo(fx,fy);
					movePreview.lineTo(tx,ty);

					movePreview.moveTo(tx,ty);
					movePreview.lineTo( tx + Math.cos(a+M.PI*0.8)*arrow, ty + Math.sin(a+M.PI*0.8)*arrow );

					movePreview.moveTo(tx,ty);
					movePreview.lineTo( tx + Math.cos(a-M.PI*0.8)*arrow, ty + Math.sin(a-M.PI*0.8)*arrow );

				case _:
			}

		}
	}


	public function getSelectedEntityInstance() : Null<led.inst.EntityInstance> {
		if( isEmpty() )
			return null;

		switch group.get(0) {
			case null, IntGrid(_), Tile(_):
				return null;

			case PointField(li, ei, fi, arrayIdx):
				return ei;

			case Entity(curLayerInstance, instance):
				return instance;
		}
	}


	override function onHistorySaving() {
		super.onHistorySaving();

		var ei = getSelectedEntityInstance(); // TODO still needed?
		if( ei!=null )
			editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
	}


	function moveSelection(m:MouseCoords, isOnStop:Bool) : Bool {
		if( isOnStop ) {
			var changed = group.move(origin, m);
			updateSelectionCursors();
			return changed;
		}
		else {
			group.showGhost(origin, m);
			return false;
		}
	}


	override function useAt(m:MouseCoords, isOnStop:Bool):Bool {
		if( any() && isRunning() && moveStarted )
			return moveSelection(m, isOnStop);
		else
			return super.useAt(m,isOnStop);
	}

	override function update() {
		super.update();
	}
}