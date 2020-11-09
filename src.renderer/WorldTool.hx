class WorldTool extends dn.Process {
	static var DRAG_THRESHOLD = 4;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var clickedLevel : Null<data.Level>;
	var levelOriginX : Int;
	var levelOriginY : Int;
	var origin : MouseCoords;
	var dragStarted = false;
	var worldMode(get,never) : Bool; inline function get_worldMode() return editor.worldMode;

	public function new() {
		super(Editor.ME);
	}

	override function toString() {
		return Type.getClassName( Type.getClass(this) )
			+ ( isTakingPriority() ? " (PRIORITY)" : "" );
	}

	public function onMouseDown(m:MouseCoords, buttonId:Int) {
		if( buttonId!=0 || App.ME.hasAnyToggleKeyDown() )
			return;

		origin = m;
		dragStarted = false;
		clickedLevel = getLevelAt(m.worldX, m.worldY, worldMode);

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
		}
	}

	public function onMouseUp(m:MouseCoords) {
		if( clickedLevel!=null )
			if( dragStarted ) {
				// Drag complete
				editor.ge.emit( LevelSettingsChanged(clickedLevel) );
			}
			else if( origin.getPageDist(m)<=DRAG_THRESHOLD ) {
				// Pick level
				var old = editor.curLevel;
				editor.selectLevel(clickedLevel);
				editor.levelRender.focusLevelX -= ( editor.curLevel.worldX-old.worldX );
				editor.levelRender.focusLevelY -= ( editor.curLevel.worldY-old.worldY );
				editor.worldMode = false;
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
				editor.worldMode = !worldMode;
				editor.levelRender.updateWorld();
		}
	}

	public function onMouseMove(m:MouseCoords) {
		// Start dragging
		if( worldMode && !dragStarted && clickedLevel!=null && origin.getPageDist(m)>=DRAG_THRESHOLD )
			dragStarted = true;

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			var initialX = clickedLevel.worldX;
			var initialY = clickedLevel.worldY;
			clickedLevel.worldX = levelOriginX + ( m.worldX - origin.worldX );
			clickedLevel.worldY = levelOriginY + ( m.worldY - origin.worldY );

			// Snap to grid
			if( settings.grid ) {
				var g = getWorldGrid();
				clickedLevel.worldX = Std.int( clickedLevel.worldX/g ) * g;
				clickedLevel.worldY = Std.int( clickedLevel.worldY/g ) * g;
			}

			// Snapping
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

			// Compensate viewport induced movement
			if( clickedLevel==editor.curLevel ) {
				editor.levelRender.focusLevelX -= ( clickedLevel.worldX - initialX );
				editor.levelRender.focusLevelY -= ( clickedLevel.worldY - initialY );
			}

			editor.levelRender.updateWorld();
		}
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