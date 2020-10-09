package tool;

class SelectionTool extends Tool<Int> {
	var moveStarted = false;
	var movePreview : h2d.Graphics;
	var isCopy = false;
	var group : GenericLevelElementGroup;

	public function new() {
		super();

		movePreview = new h2d.Graphics();
		editor.levelRender.root.add(movePreview, Const.DP_UI);

		group = new GenericLevelElementGroup();
	}

	override function onDispose() {
		super.onDispose();
		movePreview.remove();
		group.dispose();
	}

	override function getDefaultValue() return -1; // Not actually used

	public function selectAllInLayer(li:led.inst.LayerInstance, append=false) {
		if( !append )
			group.clear();

		switch li.def.type {
			case IntGrid, Tiles:
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( li.hasAnyGridValue(cx,cy) )
						group.add( GridCell(li,cx,cy) );
				}

			case Entities:
				for(ei in li.entityInstances) {
					group.add( Entity(li,ei) );

					for(fi in ei.fieldInstances)
						if( fi.def.type==F_Point )
							for(i in 0...fi.getArrayLength())
								if( !fi.valueIsNull(i) )
									group.add( PointField(li,ei,fi,i) );
				}

			case AutoLayer:
		}
	}

	public function select(?elems:Array<GenericLevelElement>, append=false) {
		if( !append )
			group.clear();

		if( elems!=null )
			for(ge in elems)
				group.add(ge);

		if( isSingle() ) {
			// Change layer
			var li = group.getSmartRelativeLayerInstance();
			if( li!=editor.curLayerInstance )
				editor.selectLayerInstance(li);

			// Selection effect
			if( group.length()==1 )
				switch group.get(0) {
					case GridCell(li, cx, cy):
						if( li.hasAnyGridValue(cx,cy) )
							switch li.def.type {
								case IntGrid:
									var v = li.getIntGrid(cx,cy);
									var t = editor.curTool.as(tool.lt.IntGridTool);
									if( t!=null )
										t.selectValue(v);
									editor.levelRender.bleepRectPx( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, li.getIntGridColorAt(cx,cy) );

								case Tiles:
									var tid = li.getGridTile(cx,cy);

									var t = editor.curTool.as(tool.lt.TileTool);
									if( t!=null )
										t.selectValue( { ids:[tid], mode:t.getMode() } ); // TODO re-support picking saved selections?

									editor.levelRender.bleepRectPx( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, 0xffcc00 );

								case AutoLayer:
								case Entities:
							}

					case Entity(li, ei):
						var t = editor.curTool.as(tool.lt.EntityTool);
						if( t!=null )
							t.selectValue(ei.defUid);
						editor.levelRender.bleepRectPx( ei.left, ei.top, ei.def.width, ei.def.height, ei.def.color );
						ui.EntityInstanceEditor.openFor(ei);

					case PointField(li, ei, fi, arrayIdx):
						var t = editor.curTool.as(tool.lt.EntityTool);
						if( t!=null )
							t.selectValue(ei.defUid);

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

			case GridCell(li, cx, cy):
				if( li.hasAnyGridValue(cx,cy) )
					switch li.def.type {
						case IntGrid:
							var id = li.getIntGridIdentifierAt(cx,cy);
							editor.cursor.set(
								GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ),
								id==null ? "#"+li.getIntGrid(cx,cy) : id
							);

						case Tiles:
							editor.cursor.set(
								Tiles(li, [li.getGridTile(cx,cy)], cx, cy),
								"Tile "+li.getGridTile(cx,cy)
							);

						case Entities:
						case AutoLayer:
					}


			case Entity(li, ei):
				editor.cursor.set(
					Entity(li, ei.def, ei, ei.x, ei.y),
					ei.def.identifier,
					true
				);

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				if( pt!=null )
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
				case GridCell(li, cx, cy):
					if( m.getLayerCx(li)==cx && m.getLayerCy(li)==cy )
						return true;

				case Entity(li, ei):
					if( ei.isOver(m.layerX, m.layerY) )
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
				if( group.hasIncompatibleGridSizes() ) {
					new ui.modal.dialog.Message(L.t._("This selection can't be moved around because it contains elements from using different grid sizes."));
					stopUsing(m);
				}
			}
			else {
				// Start a new selection
				if( !rectangle ) {
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

		if( !rectangle && !moveStarted )
			select()
		else if( rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			if( r.wid==1 && r.hei==1 ) {
				// Pick single value, in the end
				var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
				if( ge!=null )
					select([ ge ], true);
				else
					select();
			}
			else {
				// Pick every objects under rectangle
				var leftPx = M.imin( origin.levelX, m.levelX );
				var rightPx = M.imax( origin.levelX, m.levelX );
				var topPx = M.imin( origin.levelY, m.levelY );
				var bottomPx = M.imax( origin.levelY, m.levelY );

				var all : Array<GenericLevelElement> = [];
				function _addRectFromLayer(li:led.inst.LayerInstance) {
					if( !editor.levelRender.isLayerVisible(li) )
						return;

					var cLeft = Std.int( (leftPx-li.pxOffsetX) / li.def.gridSize );
					var cRight = Std.int( (rightPx-li.pxOffsetX) / li.def.gridSize );
					var cTop = Std.int( (topPx-li.pxOffsetY) /li.def.gridSize );
					var cBottom = Std.int( (bottomPx-li.pxOffsetY) /li.def.gridSize );

					for( cy in cTop...cBottom+1 )
					for( cx in cLeft...cRight+1 ) {
						if( li.hasAnyGridValue(cx,cy) )
							all.push( GridCell(li,cx,cy) );
					}

					// Entities
					if( li.def.type==Entities ) {
						for(ei in li.entityInstances) {
							if( ei.getCx(li.def)>=cLeft && ei.getCx(li.def)<=cRight && ei.getCy(li.def)>=cTop && ei.getCy(li.def)<=cBottom )
								all.push( Entity(li,ei) );

							// Entity points
							for(fi in ei.fieldInstances) {
								if( fi.def.type!=F_Point )
									continue;

								for(i in 0...fi.getArrayLength()) {
									var pt = fi.getPointGrid(i);
									if( pt!=null && pt.cx>=cLeft && pt.cx<=cRight && pt.cy>=cTop && pt.cy<=cBottom )
										all.push( PointField(li, ei, fi, i) );
								}
							}
						}
					}
				}

				if( editor.singleLayerMode )
					_addRectFromLayer( editor.curLayerInstance );
				else {
					for(li in editor.curLevel.layerInstances)
						_addRectFromLayer(li);
				}
				select(all, true);
			}
		}
		movePreview.clear();
		if( moveStarted )
			group.onMoveEnd();
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
			group.onMoveStart();
			moveStarted = true;
		}
	}


	override function saveToHistory() {
		// No super() call

		// var allInsts = group.getSelectedLayerInstances(); // BUG doesn't work if selection becomes empty after some discards

		// for(ge in group.all())
		// 	switch ge {
		// 		case IntGrid(li, cx, cy), Tile(li, cx, cy):
		// 			editor.curLevelHistory.markChange(cx,cy);

		// 		case Entity(li, ei):
		// 			// TODO

		// 		case PointField(li, ei, fi, arrayIdx):
		// 			var pt = fi.getPointGrid(arrayIdx);
		// 			if( pt!=null )
		// 				editor.curLevelHistory.markChange(pt.cx, pt.cy);
		// 	}

		// for(li in allInsts)
		// 	editor.curLevelHistory.saveLayerState(li);

		editor.curLevelHistory.flushChangeMarks();
	}


	override function onKeyPress(keyId:Int) {
		super.onKeyPress(keyId);

		switch keyId {
			case K.DELETE:
				var layerInsts = group.getSelectedLayerInstances();
				group.deleteSelecteds();
				for(li in layerInsts) {
					editor.curLevelHistory.saveLayerState(li);
					editor.levelRender.invalidateLayer(li);
				}
				editor.ge.emit(LayerInstanceChanged);
				select();
		}
	}

	override function useAt(m:MouseCoords, isOnStop:Bool):Bool {
		if( any() && isRunning() && moveStarted ) {
			if( isOnStop ) {
				// Move actual data
				var changedLayers = group.moveSelecteds(origin, m, isCopy);
				for(li in changedLayers)
					editor.curLevelHistory.saveLayerState(li);

				return changedLayers.length>0;
			}
			else {
				// Just move the ghost
				group.showGhost(origin, m, isCopy);
				return false;
			}
		}
		else
			return super.useAt(m,isOnStop);
	}

	override function update() {
		super.update();
	}

	override function postUpdate() {
		super.postUpdate();

		group.onPostUpdate();
	}
}