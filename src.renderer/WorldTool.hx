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
	var dragStarted = false;
	var worldMode(get,never) : Bool; inline function get_worldMode() return editor.worldMode;

	var helpers : h2d.Graphics;
	var linearInsertPoints : Array<LinearInsertPoint> = [];

	public function new() {
		super(Editor.ME);
		helpers = new h2d.Graphics();
		editor.worldRender.root.add(helpers, Const.DP_UI);
	}

	override function onDispose() {
		super.onDispose();
		helpers.remove();
	}

	override function toString() {
		return Type.getClassName( Type.getClass(this) )
			+ ( isTakingPriority() ? " (PRIORITY)" : "" );
	}

	public function onMouseDown(m:Coords, buttonId:Int) {
		if( buttonId!=0 || App.ME.hasAnyToggleKeyDown() )
			return;

		// Init possible insert points in linear modes
		switch project.worldLayout {
			case Free:

			case LinearHorizontal:
				var idx = 0;
				linearInsertPoints = project.levels.map( (l)->{ pos:l.worldX, idx:idx++ } );

				var last = project.levels[project.levels.length-1];
				linearInsertPoints.push({ pos:last.worldX+last.pxWid, idx:idx });
		}


		helpers.clear();
		origin = m;
		dragStarted = false;
		clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode);

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
		}
	}

	public function onMouseUp(m:Coords) {
		helpers.clear();
		if( clickedLevel!=null )
			if( dragStarted ) {
				// Drag complete
				var initialX = clickedLevel.worldX;
				var initialY = clickedLevel.worldY;

				switch project.worldLayout {
					case Free:
					case LinearHorizontal:
						var i = getInsertPoint(m);
						if( i!=null ) {
							var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
							var toIdx = i.idx>curIdx ? i.idx-1 : i.idx;
							project.sortLevel(curIdx, toIdx);
							project.reorganizeWorld();
						}
				}

				editor.ge.emit( LevelSettingsChanged(clickedLevel) );
			}
			else if( origin.getPageDist(m)<=DRAG_THRESHOLD ) {
				// Pick level
				var old = editor.curLevel;
				editor.setWorldMode(false);
				editor.selectLevel(clickedLevel);
				editor.camera.autoScrollToLevel(clickedLevel);
			}

		clickedLevel = null;
	}

	public function isTakingPriority() {
		return clickedLevel!=null || worldMode;
	}

	inline function getWorldGrid() return 16;

	inline function checkSnap(cur:Int, with:Int, curOffset=0) {
		if( M.fabs(cur+curOffset-with) <= getWorldGrid() )
			return with-curOffset;
		else
			return cur;
	}

	public function onKeyPress(keyCode:Int) {
		switch keyCode {
			case K.W:
				editor.setWorldMode( !worldMode );

		}
	}

	public function onMouseMove(m:Coords) {
		// Start dragging
		if( worldMode && !dragStarted && clickedLevel!=null && origin.getPageDist(m)>=DRAG_THRESHOLD )
			dragStarted = true;

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			// Init helpers render
			helpers.clear();
			helpers.lineStyle(10, 0x72feff, 0.5);

			// Drag
			var allowX = switch project.worldLayout {
				case Free: true;
				case LinearHorizontal: true;
			}
			var allowY = switch project.worldLayout {
				case Free: true;
				case LinearHorizontal: false;
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

						// X
						if( clickedLevel.worldY+clickedLevel.pxHei >= l.worldY-snapDist && clickedLevel.worldY <= l.worldY+l.pxHei+snapDist ) {
							clickedLevel.worldX = checkSnap( clickedLevel.worldX, l.worldX+l.pxWid );
							clickedLevel.worldX = checkSnap( clickedLevel.worldX, l.worldX+l.pxWid, clickedLevel.pxWid );
							clickedLevel.worldX = checkSnap( clickedLevel.worldX, l.worldX  );
							clickedLevel.worldX = checkSnap( clickedLevel.worldX, l.worldX, clickedLevel.pxWid );
						}

						// Y
						if( clickedLevel.worldX+clickedLevel.pxWid>= l.worldX-snapDist && clickedLevel.worldX < l.worldX+l.pxWid+snapDist ) {
							clickedLevel.worldY = checkSnap( clickedLevel.worldY, l.worldY+l.pxHei );
							clickedLevel.worldY = checkSnap( clickedLevel.worldY, l.worldY+l.pxHei, clickedLevel.pxHei );
							clickedLevel.worldY = checkSnap( clickedLevel.worldY, l.worldY );
							clickedLevel.worldY = checkSnap( clickedLevel.worldY, l.worldY, clickedLevel.pxHei );
						}
					}

				case LinearHorizontal:
					var i = getInsertPoint(m);
					if( i!=null ) {
						helpers.moveTo(i.pos, -1000);
						helpers.lineTo(i.pos, 1000);
					}
			}

			// Refresh render
			editor.worldRender.updateLayout();
		}

		// Cursor
		// for( l in editor.project.levels )
		// 	if( l.isWorldOver(m.worldX, m.worldY) )
		// 		editor.cursor.set(Move);
	}

	function getInsertPoint(m:Coords) : Null<LinearInsertPoint> {
		if( project.levels.length<=1 )
			return null;

		var curIdx = dn.Lib.getArrayIndex(clickedLevel, project.levels);
		var dh = new dn.DecisionHelper(linearInsertPoints);
		dh.remove( (i)->i.idx==curIdx+1 );
		dh.score( (i)->return -M.fabs(m.worldX-i.pos) );
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