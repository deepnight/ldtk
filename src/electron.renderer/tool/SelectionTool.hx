package tool;

class SelectionTool extends Tool<Int> {
	var moveStarted = false;
	var startedOverSelecton = false;
	var movePreview : h2d.Graphics;
	var isCopy = false;
	var group : GenericLevelElementGroup;

	public function new() {
		super();

		canUseOutOfBounds = true;
		movePreview = new h2d.Graphics();
		editor.levelRender.root.add(movePreview, Const.DP_UI);

		group = new GenericLevelElementGroup();
	}

	override function onDispose() {
		super.onDispose();
		movePreview.remove();
		group.dispose();
	}

	override function onGlobalEvent(ev:GlobalEvent) {
		super.onGlobalEvent(ev);
		switch ev {
			case TilesetImageLoaded(_): clear();
			case LevelRestoredFromHistory(_): clear();
			case LayerInstancesRestoredFromHistory(_): clear();
			case _:
		}
	}

	override function getDefaultValue() return -1; // Not actually used

	public function selectAllInLayers(level:data.Level, lis:Array<data.inst.LayerInstance>) {
		clear();

		for(li in lis) {
			if( !li.def.canSelectWhenInactive && li!=editor.curLayerInstance )
				continue;

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

		if( settings.v.emptySpaceSelection && !group.isEmpty() )
			group.addSelectionRect(0, level.pxWid, 0, level.pxHei);
	}

	public function select(?elems:Array<GenericLevelElement>, append=false) {
		if( !append )
			clear();

		if( elems!=null )
			for(ge in elems)
				group.add(ge);

		if( group.selectedElementsCount()>1 ) {
			editor.clearResizeTool();
			ui.EntityInstanceEditor.closeExisting();
		}
		else if( group.selectedElementsCount()==1 ) {
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
								editor.levelRender.bleepLayerRectCase( li, cx, cy, 1,1, li.getIntGridColorAt(cx,cy) );

							case Tiles:
								var tileInf = li.getTopMostGridTile(cx,cy);

								var t = editor.curTool.as(tool.lt.TileTool);
								if( t!=null && t.curTilesetDef!=null ) {
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

								editor.levelRender.bleepLayerRectCase( li, cx, cy, 1,1, 0xffcc00 );

							case AutoLayer:
							case Entities:
						}

				case Entity(li, ei):
					if( changedLayer )
						select([ge]);
					var t = editor.curTool.as(tool.lt.EntityTool);
					if( t!=null )
						t.selectValue(ei.defUid);
					editor.levelRender.bleepEntity(ei);
					ui.EntityInstanceEditor.openFor(ei);
					editor.createResizeToolFor(ge);

				case PointField(li, ei, fi, arrayIdx):
					var t = editor.curTool.as(tool.lt.EntityTool);
					if( t!=null )
						t.selectValue(ei.defUid);

					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null)
						editor.levelRender.bleepLayerRectCase( li, pt.cx, pt.cy, 1, 1, ei.def.color );
					ui.EntityInstanceEditor.openFor(ei);
			}

			editor.curTool.onValuePicking();
		}
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev,m);

		// Default cursor
		if( isRunning() && rectangle ) {
			var r = Rect.fromCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, 0xffffff) );
			ev.cancel = true;
		}
		else if( isRunning() ) {
			editor.cursor.set(Moving);
			ev.cancel = true;
		}
		else if( group.isOveringSelection(m) ) {
			editor.cursor.set(Move);
			ev.cancel = true;
		}
		else if( !isRunning() ) {
			// Preview picking
			var ge = editor.getGenericLevelElementAt(m, settings.v.singleLayerMode);
			ev.cancel = true;

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
				editor.cursor.set( Entity(li, ei.def, ei, ei.x, ei.y, true), ei.def.identifier );

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				if( pt!=null )
					editor.cursor.set( GridCell(li, pt.cx, pt.cy, ei.getSmartColor(false)) );
			}

			if( ge!=null )
				editor.cursor.overrideNativeCursor("grab");
		}
	}

	public function selectAndStartUsing(ev:hxd.Event, m:Coords, e:GenericLevelElement) {
		startUsing(ev, m, "noDefaultSelection");
		select([e]);
	}

	override function startUsing(ev:hxd.Event, m:Coords, ?extraParam:String) {
		isCopy = App.ME.isCtrlCmdDown() && App.ME.isAltDown();
		moveStarted = false;
		startedOverSelecton = false;
		editor.clearSpecialTool();
		movePreview.clear();

		super.startUsing(ev,m, extraParam);

		if( ev.button==0 && extraParam!="noDefaultSelection" ) {
			if( group.isOveringSelection(m) ) {
				startedOverSelecton = true;
				// Move existing selection
				if( group.hasIncompatibleGridSizes() ) {
					new ui.modal.dialog.Message(L.t._("This selection can't be moved around because it contains elements using different grid sizes."));
					stopUsing(m);
				}
				ev.cancel = true;
			}
			else {
				// Start a new selection
				if( !rectangle ) {
					var ge = editor.getGenericLevelElementAt(m, settings.v.singleLayerMode);
					tool.lt.EntityTool.cancelRefChaining();
					if( ge!=null ) {
						ev.cancel = true;
						select([ ge ]);
					}
					else
						select();
				}
			}
		}
	}

	public inline function get() return getSelectedValue();
	public function clear() {
		if( !isEmpty() ) {
			group.clear();
			ui.EntityInstanceEditor.closeExisting();
			editor.clearResizeTool();
		}
	}

	/** Return TRUE if not empty **/
	public inline function any() return !group.isEmpty();

	/** Return TRUE if empty **/
	public inline function isEmpty() return group.isEmpty();

	public inline function isSingle() return group.selectedElementsCount()==1;
	public inline function isOveringSelection(m) return group.isOveringSelection(m);
	public inline function debugContent() return group.toString();

	public inline function invalidateRender() {
		group.invalidateBounds();
		group.invalidateSelectRender();
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);

		// Start moving elements only after a small elapsed mouse distance
		if( isRunning() && button==0 && !moveStarted && M.dist(origin.pageX, origin.pageY, m.pageX, m.pageY) >= 10*Const.SCALE ) {
			group.onMoveStart();
			moveStarted = true;
		}

		if( isRunning() )
			ev.cancel = true;
	}


	override function saveToHistory() {
		// No super() call
	}


	override function onKeyPress(keyId:Int) {
		super.onKeyPress(keyId);

		switch keyId {
			case K.DELETE:
				var layerInsts = group.getSelectedLayerInstances();
				if( layerInsts.length>0 ) {
					deleteSelecteds();
					for(li in layerInsts) {
						editor.levelRender.invalidateLayer(li);
						editor.ge.emit( LayerInstanceChangedGlobally(li) );
					}
					editor.curLevelTimeline.saveLayerStates(layerInsts);
					select();
				}
		}
	}

	function deleteSelecteds() {
		for(ge in group.allElements())
			switch ge {
				case null:

				case GridCell(li, cx, cy):
					if( li.hasAnyGridValue(cx,cy) ) {
						editor.curLevelTimeline.markGridChange(li, cx,cy);
						switch li.def.type {
							case IntGrid: li.removeIntGrid(cx,cy,true);
							case Tiles: li.removeAllGridTiles(cx,cy,true);
							case Entities:
							case AutoLayer:
						}
					}

				case Entity(li, ei):
					li.removeEntityInstance(ei);
					editor.curLevelTimeline.markEntityChange(ei);
					editor.ge.emitAtTheEndOfFrame( EntityInstanceRemoved(ei) );

				case PointField(li, ei, fi, arrayIdx):
					fi.removeArrayValue(arrayIdx);
					group.decrementAllFieldArrayIdxAbove(fi, arrayIdx);
					editor.ge.emitAtTheEndOfFrame( EntityFieldInstanceChanged(ei,fi) );
			}
		clear();
	}

	override function stopUsing(m:Coords) {
		super.stopUsing(m);

		movePreview.clear();
		if( moveStarted )
			group.onMoveEnd();
		else {
			if( startedOverSelecton && group.isOveringSelection(m) ) {
				// Extend selection when re-selecting entity/points
				var ge = editor.getGenericLevelElementAt(m, settings.v.singleLayerMode);
				switch ge {
				case null:
				case GridCell(li, cx, cy):
				case Entity(li, ei):
					for(fi in ei.fieldInstances)
						if( fi.def.type==F_Point )
							for(i in 0...fi.getArrayLength())
								group.add( PointField(li,ei,fi,i) );
				case PointField(li, ei, fi, arrayIdx):
					group.add( Entity(li,ei) );
					for(fi in ei.fieldInstances)
						if( fi.def.type==F_Point )
							for(i in 0...fi.getArrayLength())
								group.add( PointField(li,ei,fi,i) );

				}
			}
		}
	}


	override function useAt(m:Coords, isOnStop:Bool):Bool {
		if( any() && isRunning() && moveStarted ) {
			// Moving a selection
			if( isOnStop ) {
				// Move actual data
				var changedLayers = group.moveSelecteds(origin, m, isCopy);
				for(li in changedLayers)
					if( li!=curLayerInstance )
						editor.levelRender.invalidateLayer(li); // cur is invalidated by Tool
				editor.curLevelTimeline.saveLayerStates(changedLayers);
				editor.invalidateResizeTool();

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
			if( any() )
				switch group.getElement(0) {
					case GridCell(li, cx, cy): clear(); // selection doesn't persist for single grid cell selection
					case Entity(li, ei):
					case PointField(li, ei, fi, arrayIdx):
				}

		}

		return super.useAt(m,isOnStop);
	}


	override function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int):Bool {
		if( left==right && top==bottom ) {
			// Actually picking a single value, even though "rectangle" was triggered
			var ge = editor.getGenericLevelElementAt(m);
			if( ge!=null )
				select([ ge ], true);
			else
				select();
		}
		else {
			// Pick every objects under rectangle
			var leftPx = Std.int( curLayerInstance.pxParallaxX + left * curLayerInstance.def.scaledGridSize );
			var rightPx = Std.int( curLayerInstance.pxParallaxX + (right+1) * curLayerInstance.def.scaledGridSize - 1 );
			var topPx = Std.int( curLayerInstance.pxParallaxY + top * curLayerInstance.def.scaledGridSize );
			var bottomPx = Std.int( curLayerInstance.pxParallaxY + (bottom+1) * curLayerInstance.def.scaledGridSize - 1 );

			var all : Array<GenericLevelElement> = [];
			function _addRectFromLayer(li:data.inst.LayerInstance) {
				if( !editor.levelRender.isLayerVisible(li) )
					return;

				if( !li.def.canSelectWhenInactive && editor.curLayerInstance!=li )
					return;

				var cLeft = Std.int( (leftPx-li.pxParallaxX) / li.def.scaledGridSize );
				var cRight = Std.int( (rightPx-li.pxParallaxX) / li.def.scaledGridSize );
				var cTop = Std.int( (topPx-li.pxParallaxY) /li.def.scaledGridSize );
				var cBottom = Std.int( (bottomPx-li.pxParallaxY) /li.def.scaledGridSize );

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

			if( settings.v.singleLayerMode )
				_addRectFromLayer( editor.curLayerInstance );
			else {
				for(li in editor.curLevel.layerInstances)
					_addRectFromLayer(li);
			}
			select(all, true);

			if( settings.v.emptySpaceSelection && !group.isEmpty() )
				group.addSelectionRect(leftPx, rightPx, topPx, bottomPx);
		}

		return super.useOnRectangle(m, left, right, top, bottom);
	}


	override function postUpdate() {
		super.postUpdate();
		group.onPostUpdate();
	}
}