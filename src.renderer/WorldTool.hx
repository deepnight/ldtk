class WorldTool extends dn.Process {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var clickedLevel : Null<data.Level>;
	var levelOriginX : Int;
	var levelOriginY : Int;
	var origin : MouseCoords;
	var dragStarted = false;

	public function new() {
		super(Editor.ME);
	}

	public function onMouseDown(m:MouseCoords, buttonId:Int) {
		if( buttonId!=0 || App.ME.hasAnyToggleKeyDown() )
			return;

		origin = m;
		dragStarted = false;
		clickedLevel = getLevelAt(m.worldX, m.worldY, false);

		if( clickedLevel!=null ) {
			levelOriginX = clickedLevel.worldX;
			levelOriginY = clickedLevel.worldY;
		}
	}

	public function onMouseUp(m:MouseCoords) {
		if( clickedLevel!=null )
			if( dragStarted )
				editor.ge.emit( LevelSettingsChanged(clickedLevel) );
			else
				editor.selectLevel(clickedLevel);

		clickedLevel = null;
	}

	public function isRunning() {
		return clickedLevel!=null;
	}

	inline function getWorldGrid() return 16;

	inline function checkSnap(cur:Int, with:Int, curOffset=0) {
		if( M.fabs(cur+curOffset-with) <= getWorldGrid() )
			return with-curOffset;
		else
			return cur;
	}

	public function onMouseMove(m:MouseCoords) {
		// Start dragging
		if( !dragStarted && clickedLevel!=null && origin.getPageDist(m)>=4 )
			dragStarted = true;

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			clickedLevel.worldX = levelOriginX + ( m.worldX - origin.worldX );
			clickedLevel.worldY = levelOriginY + ( m.worldY - origin.worldY );

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

			editor.levelRender.updateWorldPositions();
		}
	}

	function getLevelAt(worldX:Int, worldY:Int, allowSelf:Bool) {
		for(l in project.levels)
			if( worldX>=l.worldX && worldX<l.worldX+l.pxWid && worldY>=l.worldY && worldY<l.worldY+l.pxHei )
				if( allowSelf || !allowSelf && l!=editor.curLevel )
					return l;
		return null;
	}
}