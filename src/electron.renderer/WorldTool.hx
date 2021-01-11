private typedef LinearInsertPoint = {
	var idx:Int;
	var pos:Int;
}

class WorldTool extends dn.Process {
	static var DRAG_THRESHOLD = 4;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var clickedLevel : Null<data.Level>;
	var levelOriginX : Int;
	var levelOriginY : Int;
	var origin : Coords;
	var clicked = false;
	var dragStarted = false;
	var worldMode(get,never) : Bool; inline function get_worldMode() return editor.worldMode;

	var tmpRender : h2d.Graphics;
	var cursor : h2d.Graphics;
	var insertCursor : h2d.Graphics;
	var clickedSameLevel = false;
	var addMode = false;

	// var addBounds : { worldX:Int, worldY:Int, pxWid:Int, pxHei:Int } = null;

	public function new() {
		super(Editor.ME);

		tmpRender = new h2d.Graphics();
		editor.worldRender.root.add(tmpRender, Const.DP_UI);

		cursor = new h2d.Graphics();
		editor.worldRender.root.add(cursor, Const.DP_UI);

		insertCursor = new h2d.Graphics();
		editor.worldRender.root.add(insertCursor, Const.DP_UI);
	}

	override function onDispose() {
		super.onDispose();
		tmpRender.remove();
		cursor.remove();
		insertCursor.remove();
	}

	override function toString() {
		return Type.getClassName( Type.getClass(this) )
			+ ( dragStarted ? " (DRAGGING)" : "" );
	}


	public function startAddMode() {
		addMode = true;
	}

	public inline function isInAddMode() return addMode;

	public function stopAddMode() {
		addMode = false;
		insertCursor.visible = false;
	}

	public function onWorldModeChange(active:Bool) {
		insertCursor.visible = false;
		stopAddMode();
	}

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		// Right click context menu
		if( ev.button==1 && worldMode ) {
			var ctx = new ui.modal.ContextMenu(m);
			// Create
			ctx.add("New level", ()->{
				if( !createLevelAt(m) ) {
					new ui.modal.dialog.Confirm(L.t._("No room for a level here! Do you want to pick another location?"), startAddMode);
				}
			});
			var l = getLevelAt(m.worldX, m.worldY, true);
			if( l!=null ) {
				editor.selectLevel(l);
				// Duplicate
				ctx.add("Duplicate", ()->{
					var copy = project.duplicateLevel(l);
					editor.selectLevel(copy);
					switch project.worldLayout {
						case Free, GridVania:
							copy.worldX += project.defaultGridSize*4;
							copy.worldY += project.defaultGridSize*4;

						case LinearHorizontal:
						case LinearVertical:
					}
					editor.ge.emit( LevelAdded(copy) );
				});
				// Delete
				ctx.add("Delete", ()->{
					var closest = project.getClosestLevelFrom(l);
					new ui.LastChance('Level ${l.identifier} removed', project);
					project.removeLevel(l);
					editor.ge.emit( LevelRemoved(l) );
					editor.selectLevel( closest );
					editor.camera.scrollToLevel(closest);
				});
			}
			ev.cancel = true;
			return;
		}


		if( ev.button!=0 || App.ME.isShiftDown() )
			return;


		editor.camera.cancelAllAutoMovements();

		tmpRender.clear();
		origin = m;
		dragStarted = false;
		clicked = true;
		clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode);

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
			ev.cancel = true;
			clickedSameLevel = editor.curLevel==clickedLevel;
		}
		else if( addMode && getLevelInsertBounds(m)!=null )
			ev.cancel = true;
	}

	public function onMouseUp(m:Coords) {
		tmpRender.clear();

		if( clickedLevel!=null ) {
			if( dragStarted ) {
				// Drag complete
				var initialX = clickedLevel.worldX;
				var initialY = clickedLevel.worldY;

				switch project.worldLayout {
					case Free, GridVania:
					case LinearHorizontal:
						var i = getLinearInsertPoint(m,false);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							project.sortLevel(curIdx, toIdx);
							project.reorganizeWorld();
							editor.ge.emit(WorldLevelMoved);
						}

					case LinearVertical:
						var i = getLinearInsertPoint(m,false);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							project.sortLevel(curIdx, toIdx);
							project.reorganizeWorld();
							editor.ge.emit(WorldLevelMoved);
						}
				}

				editor.ge.emit( LevelSettingsChanged(clickedLevel) );
			}
			else if( origin.getPageDist(m)<=DRAG_THRESHOLD ) {
				// Pick level
				editor.selectLevel(clickedLevel);
				if( clickedSameLevel )
					editor.setWorldMode(false);
				else if( !worldMode )
					editor.camera.scrollTo(m.worldX, m.worldY);
			}
		}
		else if( worldMode && clicked && !dragStarted && addMode )
			createLevelAt(m);

		// Cleanup
		clickedLevel = null;
		dragStarted = false;
		clicked = false;
	}

	function createLevelAt(m:Coords) {
		var b = getLevelInsertBounds(m);
		if( b!=null ) {
			var l = switch project.worldLayout {
				case Free, GridVania:
					var l = project.createLevel();
					l.worldX = M.round(b.x);
					l.worldY = M.round(b.y);
					l.pxWid = b.wid;
					l.pxHei = b.hei;
					l;

				case LinearHorizontal, LinearVertical:
					var i = getLinearInsertPoint(m, true);
					if( i!=null ) {
						var l = project.createLevel(i.idx);
						l;
					}
					else
						null;
			}
			if( l!=null ) {
				N.msg("New level created");
				stopAddMode();
				project.reorganizeWorld();
				editor.ge.emit( LevelAdded(l) );
				editor.selectLevel(l);
				editor.camera.scrollToLevel(l);
			}
			return true;
		}
		else
			return false;
	}

	inline function getLevelSnapDist() return project.getSmartLevelGridSize() / ( editor.camera.adjustedZoom * 0.4 );

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

	inline function boundsOverlaps(l:data.Level, x,y,w,h) {
		return dn.Lib.rectangleOverlaps( x, y, w, h, l.worldX, l.worldY, l.pxWid, l.pxHei );
	}

	function getLevelInsertBounds(m:Coords) {
		// if( getLevelAt(m.worldX, m.worldY, true)!=null )
		// 	return null;

		var size = project.defaultGridSize * data.Project.DEFAULT_LEVEL_SIZE;

		var b = {
			x : m.worldX-size*0.5,
			y : m.worldY-size*0.5,
			wid: size,
			hei: size,
		}

		// Find a spot in world space
		switch project.worldLayout {
			case Free, GridVania:
				// Deinterlace with existing levels
				for(l in project.levels)
					if( boundsOverlaps( l, b.x, b.y, b.wid, b.hei ) ) {
						// Source: https://stackoverflow.com/questions/1585525/how-to-find-the-intersection-point-between-a-line-and-a-rectangle
						var slope = ( (b.y+b.hei*0.5)-l.worldCenterY )  /  ( (b.x+b.wid*0.5)-l.worldCenterX );
						if( slope*l.pxWid*0.5 >= -l.pxHei*0.5  &&  slope*l.pxWid*0.5 <= l.pxHei*0.5 )
							if( b.x < l.worldCenterX ) {
								b.x = l.worldX-b.wid;
							}
							else {
								b.x = l.worldX+l.pxWid;
							}
						else {
							if( b.y < l.worldCenterY ) {
								b.y = l.worldY-b.hei;
							}
							else {
								b.y = l.worldY+l.pxHei;
							}
						}
					}

				// Cancel if deinterlace failed
				for(l in project.levels)
					if( boundsOverlaps(l, b.x, b.y, b.wid, b.hei) )
						return null;

				// Grid snapping
				if( project.worldLayout==GridVania ) {
					b.x = dn.M.round( b.x/project.worldGridWidth ) * project.worldGridWidth;
					b.y = dn.M.round( b.y/project.worldGridHeight ) * project.worldGridHeight;
				}
				else if( settings.grid ) {
					b.x = dn.M.round( b.x/project.defaultGridSize ) * project.defaultGridSize;
					b.y = dn.M.round( b.y/project.defaultGridSize ) * project.defaultGridSize;
				}

			case LinearHorizontal:
				var i = getLinearInsertPoint(m, true);
				if( i!=null) {
					b.x = i.pos-b.wid*0.5;
					b.y = -32;
				}
				else
					return null;

			case LinearVertical:
				var i = getLinearInsertPoint(m, true);
				if( i!=null) {
					b.x = -32;
					b.y = i.pos-b.hei*0.5;
				}
				else
					return null;

		}


		return b;
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		if( ev.cancel ) {
			insertCursor.visible = false;
			cursor.clear();
			return;
		}

		// Start dragging
		if( clicked && worldMode && !dragStarted && origin.getPageDist(m)>=DRAG_THRESHOLD ) {
			var allow = switch project.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal, LinearVertical: project.levels.length>1;
			}
			if( allow ) {
				dragStarted = true;
				ev.cancel = true;
				if( clickedLevel!=null )
					editor.selectLevel(clickedLevel);

				if( clickedLevel!=null && ( App.ME.isAltDown() || App.ME.isCtrlDown() ) ) {
					var copy = project.duplicateLevel(clickedLevel);
					editor.ge.emit( LevelAdded(copy) );
					editor.selectLevel(copy);
					clickedLevel = copy;
				}
			}
		}

		// Rollover
		var over = getLevelAt(m.worldX, m.worldY, worldMode);
		if( over!=null ) {
			ev.cancel = true;
			cursor.clear();
			editor.cursor.set(Pointer);
			cursor.lineStyle(2/editor.camera.adjustedZoom, 0xffffff);
			cursor.beginFill(0xffcc00, 0.15);
			// var p = project.getSmartLevelGridSize()*0.5;
			cursor.drawRect(over.worldX, over.worldY, over.pxWid, over.pxHei);
			ev.cancel = true;
		}
		else
			cursor.clear();

		// Preview "add level" location
		if( addMode && !dragStarted && editor.worldMode ) {
			var bounds = getLevelInsertBounds(m);
			insertCursor.visible = bounds!=null;
			if( bounds!=null ) {
				var c = 0x8dcbfb;
				insertCursor.clear();
				insertCursor.lineStyle(2*editor.camera.pixelRatio, c, 0.7);
				insertCursor.beginFill(c, 0.3);
				insertCursor.drawRect(bounds.x, bounds.y, bounds.wid, bounds.hei);

				insertCursor.lineStyle(10*editor.camera.pixelRatio, c, 1);
				insertCursor.moveTo(bounds.x+bounds.wid*0.5, bounds.y+bounds.hei*0.3);
				insertCursor.lineTo(bounds.x+bounds.wid*0.5, bounds.y+bounds.hei*0.7);
				insertCursor.moveTo(bounds.x+bounds.wid*0.3, bounds.y+bounds.hei*0.5);
				insertCursor.lineTo(bounds.x+bounds.wid*0.7, bounds.y+bounds.hei*0.5);
				editor.cursor.set(Add);
				ev.cancel = true;
			}
		}
		else
			insertCursor.visible = false;

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			// Init tmpRender render
			tmpRender.clear();
			tmpRender.lineStyle(10, 0x72feff, 0.5);

			// Drag
			var allowX = switch project.worldLayout {
				case Free: true;
				case GridVania: true;
				case LinearHorizontal: true;
				case LinearVertical: false;
			}
			var allowY = switch project.worldLayout {
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

			switch project.worldLayout {
				case Free:
					// Snap to grid
					if( settings.grid ) {
						var g = project.getSmartLevelGridSize();
						clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
						clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;
					}

					// Snap to other levels
					for(l in project.levels) {
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

				case GridVania:
					var omx = M.floor( origin.worldX / project.worldGridWidth ) * project.worldGridWidth;
					var mx = M.floor( m.worldX / project.worldGridWidth ) * project.worldGridWidth;
					clickedLevel.worldX = levelOriginX + (mx-omx);

					var omy = M.floor( origin.worldY / project.worldGridWidth ) * project.worldGridWidth;
					var my = M.floor( m.worldY / project.worldGridWidth ) * project.worldGridWidth;
					clickedLevel.worldY = levelOriginY + (my-omy);

					clickedLevel.worldX = M.floor( clickedLevel.worldX/project.worldGridWidth ) * project.worldGridWidth;
					clickedLevel.worldY = M.floor( clickedLevel.worldY/project.worldGridHeight) * project.worldGridHeight;

				case LinearHorizontal:
					var i = getLinearInsertPoint(m,false);
					if( i!=null ) {
						tmpRender.moveTo(i.pos, -100);
						tmpRender.lineTo(i.pos, project.getWorldHeight(clickedLevel)+100);
					}

				case LinearVertical:
					var i = getLinearInsertPoint(m,false);
					if( i!=null ) {
						tmpRender.moveTo(-100, i.pos);
						tmpRender.lineTo(project.getWorldWidth(clickedLevel)+100, i.pos);
					}
			}

			// Refresh render
			editor.ge.emit( WorldLevelMoved );
			ev.cancel = true;
		}
	}

	function getLinearInsertPoint(m:Coords, forCreation:Bool) : Null<LinearInsertPoint> {
		if( project.levels.length<=1 && !forCreation )
			return null;

		// Init possible insert points in linear modes
		var pts =
			switch project.worldLayout {
				case Free, GridVania: null;

				case LinearHorizontal:
					var idx = 0;
					var all = project.levels.map( (l)->{ pos:l==clickedLevel ? levelOriginX : l.worldX, idx:idx++ } );
					var last = project.levels[project.levels.length-1];
					all.push({ pos:last.worldX+last.pxWid, idx:idx });
					all;

				case LinearVertical:
					var idx = 0;
					var all = project.levels.map( (l)->{ pos:l==clickedLevel ? levelOriginY : l.worldY, idx:idx++ } );

					var last = project.levels[project.levels.length-1];
					all.push({ pos:last.worldY+last.pxHei, idx:idx });
					all;
			}

		var dh = new dn.DecisionHelper(pts);
		if( clickedLevel!=null ) {
			var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
			dh.remove( (i)->i.idx==curIdx+1 );
		}

		switch project.worldLayout {
			case Free, GridVania:
				// N/A

			case LinearHorizontal:
				dh.score( (i)->return -M.fabs(m.worldX-i.pos) );

			case LinearVertical:
				dh.score( (i)->return -M.fabs(m.worldY-i.pos) );
		}
		return dh.getBest();
	}

	function getLevelAt(worldX:Int, worldY:Int, allowSelf:Bool) {
		if( addMode )
			return null;

		if( !allowSelf && editor.curLevel.isWorldOver(worldX,worldY) )
			return null;

		var i = project.levels.length-1;
		while( i>=0 )
			if( project.levels[i].isWorldOver(worldX,worldY) )
				return project.levels[i];
			else
				i--;

		return null;
	}
}