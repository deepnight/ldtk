private typedef WorldInsertPoint = {
	var idx:Int;
	var x:Int;
	var y:Int;
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
	var dragStarted = false;
	var worldMode(get,never) : Bool; inline function get_worldMode() return editor.worldMode;

	var tmpRender : h2d.Graphics;
	var cursor : h2d.Graphics;
	var insertPoints : Array<WorldInsertPoint> = [];

	public function new() {
		super(Editor.ME);

		tmpRender = new h2d.Graphics();
		editor.worldRender.root.add(tmpRender, Const.DP_UI);

		cursor = new h2d.Graphics();
		editor.worldRender.root.add(cursor, Const.DP_UI);
	}

	override function onDispose() {
		super.onDispose();
		tmpRender.remove();
		cursor.remove();
	}

	override function toString() {
		return Type.getClassName( Type.getClass(this) )
			+ ( dragStarted ? " (DRAGGING)" : "" );
	}

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		if( ev.button!=0 || App.ME.hasAnyToggleKeyDown() )
			return;

		// Init possible insert points in linear modes
		switch project.worldLayout {
			case Free:

			case WorldGrid:

			case LinearHorizontal:
				var idx = 0;
				insertPoints = project.levels.map( (l)->{ x:l.worldX, y:0, idx:idx++ } );

				var last = project.levels[project.levels.length-1];
				insertPoints.push({ x:last.worldX+last.pxWid, y:0, idx:idx });

			case LinearVertical:
				var idx = 0;
				insertPoints = project.levels.map( (l)->{ x:0, y:l.worldY, idx:idx++ } );

				var last = project.levels[project.levels.length-1];
				insertPoints.push({ x:0, y:last.worldY+last.pxHei, idx:idx });
		}


		tmpRender.clear();
		origin = m;
		dragStarted = false;
		clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode);

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
			ev.cancel = true;
		}
	}

	public function onMouseUp(m:Coords) {
		tmpRender.clear();
		if( clickedLevel!=null )
			if( dragStarted ) {
				// Drag complete
				var initialX = clickedLevel.worldX;
				var initialY = clickedLevel.worldY;

				switch project.worldLayout {
					case Free, WorldGrid:
					case LinearHorizontal:
						var i = getInsertPoint(m);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							project.sortLevel(curIdx, toIdx);
							project.reorganizeWorld();
							editor.ge.emit(WorldLevelMoved);
						}

					case LinearVertical:
						var i = getInsertPoint(m);
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
				var old = editor.curLevel;
				editor.setWorldMode(false);
				editor.selectLevel(clickedLevel);
			}

		clickedLevel = null;
	}

	inline function getWorldGrid() return 16;
	inline function getLevelSnapDist() return getWorldGrid() / ( editor.camera.adjustedZoom * 0.4 );

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


	public function onKeyPress(keyCode:Int) {
		switch keyCode {
			case K.W:
				editor.setWorldMode( !worldMode );

		}
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		if( ev.cancel ) {
			cursor.clear();
			return;
		}

		// Start dragging
		if( worldMode && !dragStarted && clickedLevel!=null && origin.getPageDist(m)>=DRAG_THRESHOLD ) {
			dragStarted = true;
			ev.cancel = true;
		}

		// Rollover
		var over = getLevelAt(m.worldX, m.worldY, worldMode);
		if( over!=null ) {
			ev.cancel = true;
			cursor.clear();
			editor.cursor.set(Move);
			cursor.lineStyle(1*editor.camera.pixelRatio, 0xffffff);
			cursor.beginFill(0xffcc00, 0.15);
			cursor.drawRect(over.worldX, over.worldY, over.pxWid, over.pxHei);
		}
		else
			cursor.clear();

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			// Init tmpRender render
			tmpRender.clear();
			tmpRender.lineStyle(10, 0x72feff, 0.5);

			// Drag
			var allowX = switch project.worldLayout {
				case Free: true;
				case WorldGrid: true;
				case LinearHorizontal: true;
				case LinearVertical: false;
			}
			var allowY = switch project.worldLayout {
				case Free: true;
				case WorldGrid: true;
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
						var g = getWorldGrid();
						clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
						clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;
					}

					// Snap to other levels
					var snapDist = getWorldGrid();
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

				case WorldGrid:
					var g = 256; // HACK customize that value
					clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
					clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;

				case LinearHorizontal:
					var i = getInsertPoint(m);
					if( i!=null ) {
						tmpRender.moveTo(i.x, -100);
						tmpRender.lineTo(i.x, project.getWorldHeight(clickedLevel)+100);
					}

				case LinearVertical:
					var i = getInsertPoint(m);
					if( i!=null ) {
						tmpRender.moveTo(-100, i.y);
						tmpRender.lineTo(project.getWorldWidth(clickedLevel)+100, i.y);
					}
			}

			// Refresh render
			editor.ge.emit( WorldLevelMoved );
			ev.cancel = true;
		}
	}

	function getInsertPoint(m:Coords) : Null<WorldInsertPoint> {
		if( project.levels.length<=1 )
			return null;

		var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
		var dh = new dn.DecisionHelper(insertPoints);
		dh.remove( (i)->i.idx==curIdx+1 );

		switch project.worldLayout {
			case Free, WorldGrid:
				// N/A

			case LinearHorizontal:
				dh.score( (i)->return -M.fabs(m.worldX-i.x) );

			case LinearVertical:
				dh.score( (i)->return -M.fabs(m.worldY-i.y) );
		}
		return dh.getBest();
	}

	function getLevelAt(worldX:Int, worldY:Int, allowSelf:Bool) {
		if( !allowSelf && editor.curLevel.isWorldOver(worldX,worldY) )
			return null;

		for(l in project.levels)
			if( l.isWorldOver(worldX,worldY) )
				return l;

		return null;
	}
}