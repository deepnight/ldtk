class WorldTool extends dn.Process {
	static inline function getDragThreshold() return 8*Editor.ME.camera.pixelRatio;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var clickedLevel : Null<data.Level>;
	var initialNeighbours : Null< Array<String> >;
	var levelOriginX : Int;
	var levelOriginY : Int;
	var origin : Coords;
	var clicked = false;
	var dragStarted = false;
	var worldMode(get,never) : Bool; inline function get_worldMode() return editor.worldMode;

	var tmpRender : h2d.Graphics;
	var cursor : h2d.Graphics;
	var marqueeRender : h2d.Graphics;
	var clickedSameLevel = false;

	public var selectedLevels : Array<data.Level> = [];
	var marqueeOrigin : Null<Coords>;
	var isGroupDrag = false;
	var groupDragOrigins : Null< Map<Int, {x:Int, y:Int}> >;
	var groupInitialNeighbours : Null< Map<Int, Array<String>> >;


	public function new() {
		super(Editor.ME);

		tmpRender = new h2d.Graphics();
		editor.worldRender.root.add(tmpRender, Const.DP_UI);

		cursor = new h2d.Graphics();
		editor.worldRender.root.add(cursor, Const.DP_UI);

		marqueeRender = new h2d.Graphics();
		editor.worldRender.root.add(marqueeRender, Const.DP_UI);
	}

	override function onDispose() {
		super.onDispose();
		tmpRender.remove();
		cursor.remove();
		marqueeRender.remove();
	}

	public function clearLevelSelection() {
		if( selectedLevels.length>0 ) {
			selectedLevels = [];
			editor.worldRender.updateCurrentHighlight();
		}
	}

	@:keep
	override function toString() {
		return super.toString()
			+ ( dragStarted ? " (DRAGGING)" : "" );
	}



	public function onMouseDown(ev:hxd.Event, m:Coords) {
		// Right click context menu
		if( ev.button==1 && ( worldMode || getLevelAt(m.worldX,m.worldY)==null ) && !App.ME.hasAnyToggleKeyDown() && !project.isBackup() ) {
			var ctx = new ui.modal.ContextMenu(m);
			// Create new level
			ctx.addAction({
				label: L.t._("New level"),
				cb: ()->{
					if( !ui.vp.LevelSpotPicker.tryToCreateLevelAt(project, curWorld, m) ) {
						new ui.modal.dialog.Confirm(
							L.t._("No room for a level here! Do you want to pick another location?"),
							()->new ui.vp.LevelSpotPicker()
						);
					}
				},
			});

			var l = getLevelAt(m.worldX, m.worldY);
			if( l!=null ) {
				editor.selectLevel(l);
				// Duplicate
				ctx.addAction({
					label: L.t._("Duplicate"),
					cb: ()->{
						var copy = curWorld.duplicateLevel(l);
						editor.selectLevel(copy);
						switch curWorld.worldLayout {
							case Free, GridVania:
								copy.worldX += project.defaultGridSize*4;
								copy.worldY += project.defaultGridSize*4;

							case LinearHorizontal:
							case LinearVertical:
						}
						editor.ge.emit( LevelAdded(copy) );
					}
				});

				// Delete
				ctx.addAction({
					label: L._Delete(),
					cb: ()->{
						if( curWorld.levels.length==1 ) {
							N.error(L.t._("You can't delete the last level."));
							return;
						}
						var closest = curWorld.getClosestLevelFrom(l);
						new ui.LastChance(L.t._('Level ::id:: removed', {id:l.identifier}), project);
						for(nl in l.getNeighbours())
							editor.invalidateLevelCache(nl);

						curWorld.removeLevel(l);
						editor.ge.emit( LevelRemoved(l) );
						editor.selectLevel( closest );
						editor.camera.scrollToLevel(closest);
					}
				});
			}

			if( project.worlds.length>1 ) {
				if( l==null ) {
					// Change active world
					ctx.addTitle(L.t._("Go to world:"));
					for( w in project.worlds ) {
						ctx.addAction({
							label: L.untranslated(w.identifier),
							subText: L.untranslated(w.levels.length+" level(s)"),
							enable: ()->w.iid!=editor.curWorldIid,
							cb: ()->{
								editor.selectWorld(w,true);
								editor.setWorldMode(true);
							},
						});
					}
				}
				else {
					// Move level to another world
					ctx.addTitle(L.t._("Move this level to:"));
					for( w in project.worlds ) {
						ctx.addAction({
							label: L.untranslated("➔ "+w.identifier),
							subText: L.untranslated(w.levels.length+" level(s)"),
							enable: ()->!l.isInWorld(w),
							cb: ()->{
								if( l.moveToWorld(w) ) {
									editor.selectWorld(w,true);
									editor.setWorldMode(true);
									editor.selectLevel(l);
									editor.camera.fit(true);
									N.success("Successfully moved level to world "+w.identifier);
								}
							},
						});
					}
				}
			}

			ev.cancel = true;
			return;
		}


		if( ev.button!=0 || App.ME.isShiftDown() )
			return;


		editor.camera.cancelAllAutoMovements();

		tmpRender.clear();
		origin = m;
		initialNeighbours = null;
		dragStarted = false;
		clicked = true;
		marqueeOrigin = null;
		if( !worldMode && editor.curLevel.inBoundsWorld(m.worldX,m.worldY) )
			clickedLevel = null;
		else
			clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode?null:editor.curLevel);

		if( project.isBackup() )
			clickedLevel = null;

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
			ev.cancel = true;
			clickedSameLevel = editor.curLevel==clickedLevel;
			initialNeighbours = clickedLevel.getNeighboursIids();

			if( App.ME.isCtrlCmdDown() && !App.ME.isAltDown() ) {
				// Toggle level in multi-selection
				if( selectedLevels.contains(clickedLevel) ) {
					selectedLevels.remove(clickedLevel);
					// The active level is always highlighted: hand the role over to a
					// remaining selected level so the unselected one loses its border
					if( editor.curLevel==clickedLevel && selectedLevels.length>0 )
						editor.selectLevel( selectedLevels[selectedLevels.length-1] );
				}
				else {
					selectedLevels.push(clickedLevel);
					editor.selectLevel(clickedLevel);
				}
				editor.worldRender.updateCurrentHighlight();
			}
			else if( !worldMode || !selectedLevels.contains(clickedLevel) ) {
				// Pick level (discards any multi-selection)
				selectedLevels = [clickedLevel];
				editor.selectLevel(clickedLevel);
				editor.worldRender.updateCurrentHighlight();
			}
			// NOTE: in world mode, a plain click on a level already in the multi-selection is
			// resolved on mouse-up only: dragging moves the whole group, releasing collapses
			// the selection down to the clicked level.
		}
		else if( worldMode && !project.isBackup() )
			marqueeOrigin = m;
	}

	public function onMouseUp(m:Coords) {
		tmpRender.clear();
		marqueeRender.clear();

		if( clickedLevel==null && marqueeOrigin!=null && worldMode ) {
			if( origin.getPageDist(m)<=getDragThreshold() ) {
				// Plain click on empty space
				clearLevelSelection();
			}
			else {
				// Select all levels intersecting the marquee rectangle
				var left = M.imin(marqueeOrigin.worldX, m.worldX);
				var right = M.imax(marqueeOrigin.worldX, m.worldX);
				var top = M.imin(marqueeOrigin.worldY, m.worldY);
				var bottom = M.imax(marqueeOrigin.worldY, m.worldY);

				if( !App.ME.isCtrlCmdDown() || App.ME.isAltDown() )
					selectedLevels = [];
				for( l in curWorld.levels )
					if( l.worldDepth==editor.curWorldDepth
						&& dn.Lib.rectangleOverlaps( left, top, right-left, bottom-top, l.worldX, l.worldY, l.pxWid, l.pxHei )
						&& !selectedLevels.contains(l) )
						selectedLevels.push(l);
				editor.worldRender.updateCurrentHighlight();
			}
		}
		else if( clickedLevel!=null ) {
			if( dragStarted ) {
				// Drag complete
				switch curWorld.worldLayout {
					case Free, GridVania:
						curWorld.applyAutoLevelIdentifiers();
						for( l in (isGroupDrag ? selectedLevels : [clickedLevel]) ) {
							var prevNeig = groupInitialNeighbours!=null && groupInitialNeighbours.exists(l.uid)
								? groupInitialNeighbours.get(l.uid)
								: initialNeighbours;
							editor.ge.emit( WorldLevelMoved(l, true, prevNeig) );
						}

					case LinearHorizontal:
						var i = ui.vp.LevelSpotPicker.getLinearInsertPoint(project, curWorld, m, clickedLevel, levelOriginX);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, curWorld.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							curWorld.sortLevel(curIdx, toIdx);
							curWorld.reorganizeWorld();
							editor.ge.emit( WorldLevelMoved(clickedLevel, true, initialNeighbours) );
						}

					case LinearVertical:
						var i = ui.vp.LevelSpotPicker.getLinearInsertPoint(project, curWorld, m, clickedLevel, levelOriginY);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, curWorld.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							curWorld.sortLevel(curIdx, toIdx);
							curWorld.reorganizeWorld();
							editor.ge.emit( WorldLevelMoved(clickedLevel, true, initialNeighbours) );
						}
				}

			}
			else if( !worldMode && getLevelAt(m.worldX, m.worldY)==clickedLevel || origin.getPageDist(m)<=getDragThreshold() ) {
			// 	// Pick level
			// 	editor.selectLevel(clickedLevel);
				// Enter level on "double-click"
				if( clickedSameLevel && !App.ME.isCtrlCmdDown() )
					editor.setWorldMode(false);
			// 	else if( !worldMode )
			// 		editor.camera.scrollTo(m.worldX, m.worldY);

				// Plain click on a member of the multi-selection: collapse selection to it
				if( !App.ME.isCtrlCmdDown() && selectedLevels.length>1 && selectedLevels.contains(clickedLevel) ) {
					selectedLevels = [clickedLevel];
					editor.selectLevel(clickedLevel);
					editor.worldRender.updateCurrentHighlight();
				}
			}
		}

		// Cleanup
		clickedLevel = null;
		dragStarted = false;
		clicked = false;
		isGroupDrag = false;
		marqueeOrigin = null;
		groupDragOrigins = null;
		groupInitialNeighbours = null;
	}

	inline function getLevelSnapDist() return App.ME.isShiftDown() || App.ME.isCtrlCmdDown() ? 0 : project.getSmartLevelGridSize() / ( editor.camera.adjustedZoom * 0.4 );

	inline function snapLevelX(cur:data.Level, offset:Int, at:Int) {
		if( M.fabs(cur.worldX + offset - at) <= getLevelSnapDist() ) {
			if( cur.willOverlapAnyLevel(at-offset, cur.worldY) )
				return false;
			else {
				cur.worldX = at-offset;
				return true;
			}
		}
		else
			return false;
	}

	inline function snapLevelY(l:data.Level, offset:Int, with:Int) {
		if( M.fabs(l.worldY + offset - with) <= getLevelSnapDist() ) {
			if( l.willOverlapAnyLevel(l.worldX, with-offset) )
				return false;
			else {
				l.worldY = with-offset;
				return true;
			}
		}
		else
			return false;
	}


	public function onKeyPress(keyCode:Int) {}

	public function onMouseMoveCursor(ev:hxd.Event, m:Coords) {
		if( ev.cancel ) {
			cursor.clear();
			return;
		}

		// Rollover
		var over = getLevelAt(m.worldX, m.worldY, worldMode?null:editor.curLevel);
		if( over!=null ) {
			ev.cancel = true;
			cursor.clear();
			editor.cursor.set(Pointer);
			cursor.lineStyle(2/editor.camera.adjustedZoom, 0xffffff);
			cursor.beginFill(0xffcc00, 0.15);
			// var p = project.getSmartLevelGridSize()*0.5;
			cursor.drawRect(over.worldX, over.worldY, over.pxWid, over.pxHei);
			ev.cancel = true;
			App.ME.requestCpu(false);
		}
		else
			cursor.clear();
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		// Marquee level selection over empty space
		if( clicked && worldMode && clickedLevel==null && marqueeOrigin!=null && origin.getPageDist(m)>=getDragThreshold() ) {
			ev.cancel = true;
			var left = M.imin(marqueeOrigin.worldX, m.worldX);
			var right = M.imax(marqueeOrigin.worldX, m.worldX);
			var top = M.imin(marqueeOrigin.worldY, m.worldY);
			var bottom = M.imax(marqueeOrigin.worldY, m.worldY);
			marqueeRender.clear();
			marqueeRender.lineStyle(2/editor.camera.adjustedZoom, 0xffcc00);
			marqueeRender.beginFill(0xffcc00, 0.1);
			marqueeRender.drawRect(left, top, right-left, bottom-top);
			marqueeRender.endFill();
			App.ME.requestCpu();
		}

		// Start dragging
		if( clicked && worldMode && !dragStarted && origin.getPageDist(m)>=getDragThreshold() ) {
			var allow = switch curWorld.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal, LinearVertical: curWorld.levels.length>1;
			}
			if( allow ) {
				dragStarted = true;
				ev.cancel = true;
				// if( clickedLevel!=null )
				// 	editor.selectLevel(clickedLevel);

				isGroupDrag = clickedLevel!=null
					&& selectedLevels.length>1
					&& selectedLevels.contains(clickedLevel)
					&& ( switch curWorld.worldLayout {
						case Free, GridVania: true;
						case LinearHorizontal, LinearVertical: false;
					} );

				if( clickedLevel!=null && App.ME.isAltDown() && App.ME.isCtrlCmdDown() ) {
					if( isGroupDrag ) {
						// Duplicate all selected levels, the copies become the dragged selection
						var oldClicked = clickedLevel;
						var copies = [];
						for( l in selectedLevels ) {
							var copy = curWorld.duplicateLevel(l);
							editor.ge.emit( LevelAdded(copy) );
							copies.push(copy);
							if( l==oldClicked )
								clickedLevel = copy;
						}
						selectedLevels = copies;
					}
					else {
						var copy = curWorld.duplicateLevel(clickedLevel);
						editor.ge.emit( LevelAdded(copy) );
						clickedLevel = copy;
					}
					editor.selectLevel(clickedLevel);
				}

				// Store pre-drag positions and neighbours of all dragged levels
				if( clickedLevel!=null ) {
					groupDragOrigins = new Map();
					groupInitialNeighbours = new Map();
					for( l in (isGroupDrag ? selectedLevels : [clickedLevel]) ) {
						if( isGroupDrag && !curWorld.levels.contains(l) )
							continue;
						groupDragOrigins.set( l.uid, { x:l.worldX, y:l.worldY } );
						groupInitialNeighbours.set( l.uid, l.getNeighboursIids() );
					}
				}
			}
		}

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			// Init tmpRender render
			tmpRender.clear();
			tmpRender.lineStyle(10, 0x72feff, 0.5);

			// Drag
			var allowX = switch curWorld.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal: true;
				case LinearVertical: false;
			}
			var allowY = switch curWorld.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal: false;
				case LinearVertical: true;
			}
			var initialX = clickedLevel.worldX;
			var initialY = clickedLevel.worldY;
			if( allowX )
				clickedLevel.worldX = levelOriginX + ( m.worldX - origin.worldX );
			else
				clickedLevel.worldX = Std.int( -clickedLevel.pxWid*0.8 );

			if( allowY )
				clickedLevel.worldY = levelOriginY + ( m.worldY - origin.worldY );
			else
				clickedLevel.worldY = Std.int( -clickedLevel.pxHei*0.8 );

			switch curWorld.worldLayout {
				case Free:
					// Snap to grid
					if( settings.v.grid ) {
						var g = project.getSmartLevelGridSize();
						clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
						clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;
					}

					// Snap to other levels (ignoring members of the dragged group)
					for(l in curWorld.levels) {
						if( l==clickedLevel || isGroupDrag && selectedLevels.contains(l) )
							continue;

						if( clickedLevel.getBoundsDist(l) > getLevelSnapDist() )
							continue;

						// X
						snapLevelX(clickedLevel, 0, l.worldX);
						snapLevelX(clickedLevel, 0, l.worldX+l.pxWid);
						snapLevelX(clickedLevel, clickedLevel.pxWid, l.worldX);
						snapLevelX(clickedLevel, clickedLevel.pxWid, l.worldX+l.pxWid);

						// Y
						snapLevelY(clickedLevel, 0, l.worldY);
						snapLevelY(clickedLevel, 0, l.worldY+l.pxHei);
						snapLevelY(clickedLevel, clickedLevel.pxHei, l.worldY);
						snapLevelY(clickedLevel, clickedLevel.pxHei, l.worldY+l.pxHei);

						// X again because if Y snapped, X snapping result might change
						snapLevelX(clickedLevel, 0, l.worldX);
						snapLevelX(clickedLevel, 0, l.worldX+l.pxWid);
						snapLevelX(clickedLevel, clickedLevel.pxWid, l.worldX);
						snapLevelX(clickedLevel, clickedLevel.pxWid, l.worldX+l.pxWid);
					}

				case GridVania:
					var omx = M.floor( origin.worldX / curWorld.worldGridWidth ) * curWorld.worldGridWidth;
					var mx = M.floor( m.worldX / curWorld.worldGridWidth ) * curWorld.worldGridWidth;
					clickedLevel.worldX = levelOriginX + (mx-omx);

					var omy = M.floor( origin.worldY / curWorld.worldGridHeight ) * curWorld.worldGridHeight;
					var my = M.floor( m.worldY / curWorld.worldGridHeight ) * curWorld.worldGridHeight;
					clickedLevel.worldY = levelOriginY + (my-omy);

					clickedLevel.worldX = M.floor( clickedLevel.worldX/curWorld.worldGridWidth ) * curWorld.worldGridWidth;
					clickedLevel.worldY = M.floor( clickedLevel.worldY/curWorld.worldGridHeight ) * curWorld.worldGridHeight;

				case LinearHorizontal:
					var i = ui.vp.LevelSpotPicker.getLinearInsertPoint(project, curWorld, m, clickedLevel, levelOriginX);
					if( i!=null ) {
						tmpRender.moveTo(i.coord, -100);
						tmpRender.lineTo(i.coord, curWorld.getWorldHeight(clickedLevel)+100);
					}

				case LinearVertical:
					var i = ui.vp.LevelSpotPicker.getLinearInsertPoint(project, curWorld, m, clickedLevel, levelOriginY);
					if( i!=null ) {
						tmpRender.moveTo(-100, i.coord);
						tmpRender.lineTo(curWorld.getWorldWidth(clickedLevel)+100, i.coord);
					}
			}

			// Move the rest of the group along with the anchor level.
			// Only the anchor snaps to grid/levels, followers inherit its delta.
			if( isGroupDrag ) {
				var dx = clickedLevel.worldX - levelOriginX;
				var dy = clickedLevel.worldY - levelOriginY;
				for( l in selectedLevels ) {
					if( l==clickedLevel || !groupDragOrigins.exists(l.uid) )
						continue;
					var o = groupDragOrigins.get(l.uid);
					l.worldX = o.x + dx;
					l.worldY = o.y + dy;
				}
			}

			// Refresh render
			for( l in (isGroupDrag ? selectedLevels : [clickedLevel]) )
				editor.ge.emit( WorldLevelMoved(l, false, null) );
			App.ME.requestCpu();
			ev.cancel = true;
		}
	}

	function getLevelAt(worldX:Int, worldY:Int, ?except:data.Level) {
		var i = curWorld.levels.length-1;
		var l : data.Level = null;
		while( i>=0 ) {
			l = curWorld.levels[i];
			if( l!=except && l.worldDepth==editor.curWorldDepth && l.isWorldOver(worldX,worldY) )
				return l;
			else
				i--;
		}

		return null;
	}
}