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

	public function selectAllInLayers(level:data.Level, lis:Array<data.inst.LayerInstance>) {
		group.clear();

		for(li in lis)
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

		if( settings.emptySpaceSelection && !group.isEmpty() )
			group.addSelectionRect(0, level.pxWid, 0, level.pxHei);
	}

	public function select(?elems:Array<GenericLevelElement>, append=false) {
		if( !append )
			group.clear();

		if( elems!=null )
			for(ge in elems)
				group.add(ge);

		if( group.selectedElementsCount()==1 ) {
			var ge = group.getElement(0);
			var li = group.getSmartRelativeLayerInstance();

			// Change layer
			var changedLayer = li!=editor.curLayerInstance;
			if( changedLayer )
				editor.selectLayerInstance(li);

			// Selection effect
			switch ge {
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
								var tileInf = li.getTopMostGridTile(cx,cy);

								var t = editor.curTool.as(tool.lt.TileTool);
								if( t!=null ) {
									var savedTileSel = t.curTilesetDef.getSavedSelectionFor(tileInf.tileId);
									if( savedTileSel!=null && !t.selectedValueHasAny(savedTileSel.ids) )
										t.selectValue({
											ids: savedTileSel.ids.copy(),
											mode: savedTileSel.mode,
										});
									else
										t.selectValue( { ids:[tileInf.tileId], mode:t.getMode() } );
									t.flipX = M.hasBit(tileInf.flips,0);
									t.flipY = M.hasBit(tileInf.flips,1);
								}

								editor.levelRender.bleepRectPx( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, 0xffcc00 );

							case AutoLayer:
							case Entities:
						}

				case Entity(li, ei):
					if( changedLayer )
						select([ge]);
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
		else if( group.isOveringSelection(m) )
			editor.cursor.set(Move);
		else if( !isRunning() ) {
			// Preview picking
			var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY, settings.singleLayerMode);
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
							var stack = li.getGridTileStack(cx,cy);
							var topTile = stack[stack.length-1];
							editor.cursor.set(
								Tiles(li, [topTile.tileId], cx, cy, topTile.flips),
								stack.length==1
									? "Tile "+stack[0].tileId
									: "Tiles "+stack.map( t->t.tileId ).join(", ")
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

	override function startUsing(m:MouseCoords, buttonId:Int) {
		isCopy = App.ME.isCtrlDown() && App.ME.isAltDown();
		moveStarted = false;
		editor.clearSpecialTool();
		movePreview.clear();

		super.startUsing(m, buttonId);

		if( buttonId==0 ) {
			if( group.isOveringSelection(m) ) {
				// Move existing selection
				if( group.hasIncompatibleGridSizes() ) {
					new ui.modal.dialog.Message(L.t._("This selection can't be moved around because it contains elements from using different grid sizes."));
					stopUsing(m);
				}
			}
			else {
				// Start a new selection
				if( !rectangle ) {
					var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY, settings.singleLayerMode);
					if( ge!=null )
						select([ ge ]);
					else
						select();
				}
			}
		}
	}

	// override function stopUsing(m:MouseCoords) {
	// 	super.stopUsing(m);
	// }

	public inline function get() return getSelectedValue();
	public function clear() {
		if( !isEmpty() )
			select();
	}
	public inline function any() return !group.isEmpty();
	public inline function isEmpty() return group.isEmpty();
	public inline function isSingle() return group.selectedElementsCount()==1;
	public inline function isOveringSelection(m) return group.isOveringSelection(m);


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

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);

		movePreview.clear();
		if( moveStarted )
			group.onMoveEnd();
	}


	override function useAt(m:MouseCoords, isOnStop:Bool):Bool {
		if( any() && isRunning() && moveStarted ) {
			// Moving a selection
			if( isOnStop ) {
				// Move actual data
				var changedLayers = group.moveSelecteds(origin, m, isCopy);
				for(li in changedLayers) {
					editor.curLevelHistory.saveLayerState(li);
					if( li!=curLayerInstance )
						editor.levelRender.invalidateLayer(li); // cur is invalidated by Tool
				}

				return changedLayers.length>0;
			}
			else {
				// Just move the ghost
				group.showGhost(origin, m, isCopy);
				return false;
			}
		}
		else if( isOnStop ) {
			// Single quick pick
			select();
		}

		return super.useAt(m,isOnStop);
	}


	override function useOnRectangle(m:MouseCoords, left:Int, right:Int, top:Int, bottom:Int):Bool {
		if( left==right && top==bottom ) {
			// Actually picking a single value, even though "rectangle" was triggered
			var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
			if( ge!=null )
				select([ ge ], true);
			else
				select();
		}
		else {
			// Pick every objects under rectangle
			var leftPx = curLayerInstance.pxTotalOffsetX + left * curLayerInstance.def.gridSize;
			var rightPx = curLayerInstance.pxTotalOffsetX + (right+1) * curLayerInstance.def.gridSize - 1;
			var topPx = curLayerInstance.pxTotalOffsetY + top * curLayerInstance.def.gridSize;
			var bottomPx = curLayerInstance.pxTotalOffsetY + (bottom+1) * curLayerInstance.def.gridSize - 1;

			var all : Array<GenericLevelElement> = [];
			function _addRectFromLayer(li:data.inst.LayerInstance) {
				if( !editor.levelRender.isLayerVisible(li) )
					return;

				var cLeft = Std.int( (leftPx-li.pxTotalOffsetX) / li.def.gridSize );
				var cRight = Std.int( (rightPx-li.pxTotalOffsetX) / li.def.gridSize );
				var cTop = Std.int( (topPx-li.pxTotalOffsetY) /li.def.gridSize );
				var cBottom = Std.int( (bottomPx-li.pxTotalOffsetY) /li.def.gridSize );

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

			if( settings.singleLayerMode )
				_addRectFromLayer( editor.curLayerInstance );
			else {
				for(li in editor.curLevel.layerInstances)
					_addRectFromLayer(li);
			}
			select(all, true);

			if( settings.emptySpaceSelection && !group.isEmpty() )
				group.addSelectionRect(leftPx, rightPx, topPx, bottomPx);
		}

		return super.useOnRectangle(m, left, right, top, bottom);
	}


	override function postUpdate() {
		super.postUpdate();
		group.onPostUpdate();
	}
}