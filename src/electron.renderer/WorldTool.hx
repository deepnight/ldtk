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
	var clickedSameLevel = false;

	// Multi-selection
	public var selectedLevels : Array<data.Level>;
	var selectionRender : h2d.Graphics;
	var rectSelectionStart : Null<Coords>;
	var rectSelectionRender : h2d.Graphics;
	var isRectSelecting = false;
	var initialLevelPositions : Map<Int, {x:Int, y:Int, neighbours:Array<String>}>;


	public function new() {
		super(Editor.ME);

		tmpRender = new h2d.Graphics();
		editor.worldRender.root.add(tmpRender, Const.DP_UI);

		cursor = new h2d.Graphics();
		editor.worldRender.root.add(cursor, Const.DP_UI);

		// Initialize multi-selection
		selectedLevels = [];
		selectionRender = new h2d.Graphics();
		editor.worldRender.root.add(selectionRender, Const.DP_UI);

		rectSelectionRender = new h2d.Graphics();
		editor.worldRender.root.add(rectSelectionRender, Const.DP_UI);

		initialLevelPositions = new Map();
	}

	override function onDispose() {
		super.onDispose();
		tmpRender.remove();
		cursor.remove();
		selectionRender.remove();
		rectSelectionRender.remove();
	}

	@:keep
	override function toString() {
		return super.toString()
			+ ( dragStarted ? " (DRAGGING)" : "" );
	}

	public function clearSelection() {
		selectedLevels = [];
		selectionRender.clear();
		// Restore yellow highlight when clearing selection
		editor.worldRender.updateCurrentHighlight();
	}

	function addToSelection(l:data.Level) {
		if( !selectedLevels.contains(l) ) {
			selectedLevels.push(l);
			updateSelectionRender();
		}
	}

	function removeFromSelection(l:data.Level) {
		selectedLevels.remove(l);
		updateSelectionRender();
	}

	function isSelected(l:data.Level) : Bool {
		return selectedLevels.contains(l);
	}

	function updateSelectionRender() {
		selectionRender.clear();

		// Update the yellow highlight visibility (hide it when multi-selecting)
		editor.worldRender.updateCurrentHighlight();

		if( selectedLevels.length == 0 )
			return;

		selectionRender.lineStyle(3/editor.camera.adjustedZoom, 0x00ff00, 0.8);
		selectionRender.beginFill(0x00ff00, 0.15);
		for( l in selectedLevels ) {
			selectionRender.drawRect(l.worldX, l.worldY, l.pxWid, l.pxHei);
		}
		App.ME.requestCpu(false);
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


		if( ev.button!=0 )
			return;

		editor.camera.cancelAllAutoMovements();

		tmpRender.clear();
		origin = m;
		initialNeighbours = null;
		dragStarted = false;
		clicked = true;

		// Handle rectangle selection start (with SHIFT for rectangle selection)
		if( App.ME.isShiftDown() && worldMode ) {
			rectSelectionStart = m;
			isRectSelecting = true;
			ev.cancel = true;
			return;
		}

		if( !worldMode && editor.curLevel.inBoundsWorld(m.worldX,m.worldY) )
			clickedLevel = null;
		else
			clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode?null:editor.curLevel);

		if( project.isBackup() )
			clickedLevel = null;

		if( clickedLevel!=null ) {
			// Handle multi-selection with CTRL/CMD
			if( App.ME.isCtrlCmdDown() && worldMode ) {
				if( isSelected(clickedLevel) ) {
					// Remove from selection
					removeFromSelection(clickedLevel);
					if( selectedLevels.length == 0 ) {
						// If no more selection, revert to single selection
						editor.selectLevel(clickedLevel);
					}
				}
				else {
					// Add to selection
					addToSelection(clickedLevel);
				}
				ev.cancel = true;
				// Still allow dragging with multi-selection
				levelOriginX = clickedLevel.worldX;
				levelOriginY = clickedLevel.worldY;
				clickedSameLevel = editor.curLevel==clickedLevel;
				initialNeighbours = clickedLevel.getNeighboursIids();
			}
			else {
				// Single click without CTRL/CMD
				// If clicking on a selected level, keep selection for dragging
				if( !isSelected(clickedLevel) ) {
					// Clear selection only if clicking on non-selected level
					clearSelection();
					editor.selectLevel(clickedLevel);
				}

				levelOriginX = clickedLevel.worldX;
				levelOriginY = clickedLevel.worldY;
				ev.cancel = true;
				clickedSameLevel = editor.curLevel==clickedLevel;
				initialNeighbours = clickedLevel.getNeighboursIids();
			}
		}
		else {
			// Clicked on empty space - start rectangle selection if in world mode
			if( worldMode ) {
				if( !App.ME.isCtrlCmdDown() )
					clearSelection();
				rectSelectionStart = m;
				isRectSelecting = true;
				ev.cancel = true;
			}
		}
	}

	public function onMouseUp(m:Coords) {
		tmpRender.clear();

		// Handle rectangle selection completion
		if( isRectSelecting ) {
			isRectSelecting = false;
			rectSelectionRender.clear();
			rectSelectionStart = null;
		}

		if( clickedLevel!=null || selectedLevels.length > 0 ) {
			if( dragStarted ) {
				// Drag complete - handle multi-level movement
				if( selectedLevels.length > 0 ) {
					// Multi-level movement
					switch curWorld.worldLayout {
						case Free, GridVania:
							curWorld.applyAutoLevelIdentifiers();
							// Emit events for all moved levels
							for( uid in initialLevelPositions.keys() ) {
								var l = project.getLevelAnywhere(uid);
								if( l != null ) {
									var data = initialLevelPositions.get(uid);
									editor.ge.emit( WorldLevelMoved(l, true, data.neighbours) );
								}
							}

						case LinearHorizontal, LinearVertical:
							// For linear layouts, only single level movement is supported
							if( clickedLevel != null ) {
								if( curWorld.worldLayout == LinearHorizontal ) {
									var i = ui.vp.LevelSpotPicker.getLinearInsertPoint(project, curWorld, m, clickedLevel, levelOriginX);
									if( i!=null ) {
										var curIdx = dn.Lib.getArrayIndex(clickedLevel, curWorld.levels);
										var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
										curWorld.sortLevel(curIdx, toIdx);
										curWorld.reorganizeWorld();
										editor.ge.emit( WorldLevelMoved(clickedLevel, true, initialNeighbours) );
									}
								}
								else {
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
					}
				}
				else if( clickedLevel != null ) {
					// Single level movement (original behavior)
					switch curWorld.worldLayout {
						case Free, GridVania:
							curWorld.applyAutoLevelIdentifiers();
							editor.ge.emit( WorldLevelMoved(clickedLevel, true, initialNeighbours) );

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
			}
			else if( clickedLevel!=null && (!worldMode && getLevelAt(m.worldX, m.worldY)==clickedLevel || origin.getPageDist(m)<=getDragThreshold()) ) {
				// Enter level on "double-click" - but not if we were selecting with CTRL/CMD
				if( clickedSameLevel && !App.ME.isCtrlCmdDown() )
					editor.setWorldMode(false);
			}
		}

		// Cleanup
		clickedLevel = null;
		dragStarted = false;
		clicked = false;
		initialLevelPositions.clear();
	}

	inline function getLevelSnapDist() return App.ME.isAltDown() ? 0 : project.getSmartLevelGridSize() / ( editor.camera.adjustedZoom * 0.4 );

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

		// Don't show yellow cursor if we have multi-selection
		if( selectedLevels.length > 0 ) {
			cursor.clear();
			return;
		}

		// Rollover
		var over = getLevelAt(m.worldX, m.worldY, worldMode?null:editor.curLevel);
		if( over!=null ) {
			ev.cancel = true;
			cursor.clear();
			editor.cursor.set(Pointer);

			// Different color if level is already selected
			if( isSelected(over) ) {
				cursor.lineStyle(2/editor.camera.adjustedZoom, 0x00ff00);
				cursor.beginFill(0x00ff00, 0.15);
			}
			else {
				cursor.lineStyle(2/editor.camera.adjustedZoom, 0xffffff);
				cursor.beginFill(0xffcc00, 0.15);
			}
			cursor.drawRect(over.worldX, over.worldY, over.pxWid, over.pxHei);
			ev.cancel = true;
			App.ME.requestCpu(false);
		}
		else
			cursor.clear();
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		// Handle rectangle selection
		if( isRectSelecting && rectSelectionStart != null ) {
			rectSelectionRender.clear();
			rectSelectionRender.lineStyle(2/editor.camera.adjustedZoom, 0x00ff00, 0.8);
			rectSelectionRender.beginFill(0x00ff00, 0.2);

			var x1 = M.fmin(rectSelectionStart.worldX, m.worldX);
			var y1 = M.fmin(rectSelectionStart.worldY, m.worldY);
			var x2 = M.fmax(rectSelectionStart.worldX, m.worldX);
			var y2 = M.fmax(rectSelectionStart.worldY, m.worldY);

			rectSelectionRender.drawRect(x1, y1, x2-x1, y2-y1);

			// Find levels within rectangle
			var newSelection = [];
			for( l in curWorld.levels ) {
				if( l.worldDepth == editor.curWorldDepth &&
					l.worldX < x2 && l.worldX + l.pxWid > x1 &&
					l.worldY < y2 && l.worldY + l.pxHei > y1 ) {
					newSelection.push(l);
				}
			}

			// Update selection
			if( !App.ME.isCtrlCmdDown() )
				selectedLevels = [];
			for( l in newSelection )
				if( !isSelected(l) )
					selectedLevels.push(l);
			updateSelectionRender();

			ev.cancel = true;
			App.ME.requestCpu();
			return;
		}

		// Start dragging
		if( clicked && worldMode && !dragStarted && origin.getPageDist(m)>=getDragThreshold() ) {
			var allow = switch curWorld.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal, LinearVertical: selectedLevels.length==0 && curWorld.levels.length>1;
			}
			if( allow ) {
				dragStarted = true;
				ev.cancel = true;

				// Initialize positions for all selected levels
				initialLevelPositions.clear();

				// If we have a clicked level but no selection, treat it as single selection
				if( clickedLevel != null && selectedLevels.length == 0 ) {
					// Single level drag
					initialLevelPositions.set(clickedLevel.uid, {
						x: clickedLevel.worldX,
						y: clickedLevel.worldY,
						neighbours: clickedLevel.getNeighboursIids()
					});
				}
				else if( selectedLevels.length > 0 ) {
					// Multi-level drag
					// Include clicked level in selection if not already
					if( clickedLevel != null && !isSelected(clickedLevel) ) {
						addToSelection(clickedLevel);
					}

					// Store initial positions for all selected levels
					for( l in selectedLevels ) {
						initialLevelPositions.set(l.uid, {
							x: l.worldX,
							y: l.worldY,
							neighbours: l.getNeighboursIids()
						});
					}
				}

				// Handle duplication with Alt+Ctrl
				if( clickedLevel!=null && App.ME.isAltDown() && App.ME.isCtrlCmdDown() ) {
					if( selectedLevels.length > 0 ) {
						// Duplicate all selected levels
						var newSelection = [];
						for( l in selectedLevels ) {
							var copy = curWorld.duplicateLevel(l);
							editor.ge.emit( LevelAdded(copy) );
							newSelection.push(copy);
							// Update initial positions for the copies
							initialLevelPositions.set(copy.uid, {
								x: copy.worldX,
								y: copy.worldY,
								neighbours: copy.getNeighboursIids()
							});
						}
						selectedLevels = newSelection;
						if( clickedLevel != null ) {
							// Find the copy of the clicked level
							for( l in newSelection ) {
								if( l.worldX == clickedLevel.worldX + project.defaultGridSize*4 &&
									l.worldY == clickedLevel.worldY + project.defaultGridSize*4 ) {
									clickedLevel = l;
									editor.selectLevel(l);
									break;
								}
							}
						}
					}
					else {
						var copy = curWorld.duplicateLevel(clickedLevel);
						editor.ge.emit( LevelAdded(copy) );
						editor.selectLevel(copy);
						clickedLevel = copy;
					}
				}
			}
		}

		// Drag
		if( (clickedLevel!=null || selectedLevels.length > 0) && dragStarted ) {
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

			// Calculate offset based on clicked level or first selected level
			var offsetX = m.worldX - origin.worldX;
			var offsetY = m.worldY - origin.worldY;

			// Move multiple selected levels
			if( selectedLevels.length > 0 ) {
				for( l in selectedLevels ) {
					var initData = initialLevelPositions.get(l.uid);
					if( initData != null ) {
						if( allowX )
							l.worldX = initData.x + offsetX;
						else
							l.worldX = Std.int( -l.pxWid*0.8 );

						if( allowY )
							l.worldY = initData.y + offsetY;
						else
							l.worldY = Std.int( -l.pxHei*0.8 );
					}
				}
			}
			else if( clickedLevel != null ) {
				// Single level movement (original behavior)
				var initialX = clickedLevel.worldX;
				var initialY = clickedLevel.worldY;
				if( allowX )
					clickedLevel.worldX = levelOriginX + offsetX;
				else
					clickedLevel.worldX = Std.int( -clickedLevel.pxWid*0.8 );

				if( allowY )
					clickedLevel.worldY = levelOriginY + offsetY;
				else
					clickedLevel.worldY = Std.int( -clickedLevel.pxHei*0.8 );
			}

			switch curWorld.worldLayout {
				case Free:
					if( selectedLevels.length > 0 ) {
						// Multi-level snapping: snap as a group using the clicked level as reference
						if( clickedLevel != null ) {
							var snapDeltaX = 0;
							var snapDeltaY = 0;

							// Snap to grid using clicked level
							if( settings.v.grid ) {
								var g = project.getSmartLevelGridSize();
								var snappedX = Std.int( clickedLevel.worldX/g ) * g;
								var snappedY = Std.int( clickedLevel.worldY/g ) * g;
								snapDeltaX = snappedX - clickedLevel.worldX;
								snapDeltaY = snappedY - clickedLevel.worldY;
							}

							// Check snapping to other levels (not in selection)
							for(l in curWorld.levels) {
								if( selectedLevels.contains(l) )
									continue;

								// Check each selected level for snapping, but apply uniformly
								for( snapLevel in selectedLevels ) {
									if( snapLevel.getBoundsDist(l) > getLevelSnapDist() )
										continue;

									// Try X snapping
									var oldX = snapLevel.worldX;
									if( snapLevelX(snapLevel, 0, l.worldX) ||
										snapLevelX(snapLevel, 0, l.worldX+l.pxWid) ||
										snapLevelX(snapLevel, snapLevel.pxWid, l.worldX) ||
										snapLevelX(snapLevel, snapLevel.pxWid, l.worldX+l.pxWid) ) {
										snapDeltaX = snapLevel.worldX - oldX;
									}
									snapLevel.worldX = oldX; // Reset for now

									// Try Y snapping
									var oldY = snapLevel.worldY;
									if( snapLevelY(snapLevel, 0, l.worldY) ||
										snapLevelY(snapLevel, 0, l.worldY+l.pxHei) ||
										snapLevelY(snapLevel, snapLevel.pxHei, l.worldY) ||
										snapLevelY(snapLevel, snapLevel.pxHei, l.worldY+l.pxHei) ) {
										snapDeltaY = snapLevel.worldY - oldY;
									}
									snapLevel.worldY = oldY; // Reset
								}
							}

							// Apply snap delta uniformly to all selected levels
							if( snapDeltaX != 0 || snapDeltaY != 0 ) {
								for( l in selectedLevels ) {
									l.worldX += snapDeltaX;
									l.worldY += snapDeltaY;
								}
							}
						}
					}
					else if( clickedLevel != null ) {
						// Single level snapping (original behavior)
						// Snap to grid
						if( settings.v.grid ) {
							var g = project.getSmartLevelGridSize();
							clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
							clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;
						}

						// Snap to other levels
						for(l in curWorld.levels) {
							if( l==clickedLevel )
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
					}

				case GridVania:
					if( selectedLevels.length > 0 ) {
						// Multi-level snapping for GridVania
						if( clickedLevel != null ) {
							var snappedX = M.floor( clickedLevel.worldX/curWorld.worldGridWidth ) * curWorld.worldGridWidth;
							var snappedY = M.floor( clickedLevel.worldY/curWorld.worldGridHeight ) * curWorld.worldGridHeight;
							var snapDeltaX = snappedX - clickedLevel.worldX;
							var snapDeltaY = snappedY - clickedLevel.worldY;

							// Apply uniform snapping to all selected levels
							for( l in selectedLevels ) {
								l.worldX += snapDeltaX;
								l.worldY += snapDeltaY;
							}
						}
					}
					else if( clickedLevel != null ) {
						// Single level snapping
						clickedLevel.worldX = M.floor( clickedLevel.worldX/curWorld.worldGridWidth ) * curWorld.worldGridWidth;
						clickedLevel.worldY = M.floor( clickedLevel.worldY/curWorld.worldGridHeight ) * curWorld.worldGridHeight;
					}

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

			// Refresh render for all moved levels
			if( selectedLevels.length > 0 ) {
				for( l in selectedLevels )
					editor.ge.emit( WorldLevelMoved(l, false, null) );
				// Update selection visualization during drag
				updateSelectionRender();
			}
			else if( clickedLevel != null )
				editor.ge.emit( WorldLevelMoved(clickedLevel, false, null) );

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