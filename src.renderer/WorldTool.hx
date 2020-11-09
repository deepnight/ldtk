class WorldTool extends dn.Process {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var clickedLevel : Null<data.Level>;
	var origin : MouseCoords;
	var dragStarted = false;

	public function new() {
		super(Editor.ME);
	}

	public function onMouseDown(m:MouseCoords) {
		origin = m;
		dragStarted = false;
		clickedLevel = getLevelAt(m.worldX, m.worldY, false);
	}

	public function onMouseUp(m:MouseCoords) {
		clickedLevel = null;
	}

	public function onMouseMove(m:MouseCoords) {
		// Start dragging
		if( !dragStarted && clickedLevel!=null && origin.getPageDist(m)>=4 )
			dragStarted = true;

		// Drag
		if( clickedLevel!=null && dragStarted ) {
			clickedLevel.worldX += ( m.worldX - origin.worldX );
			clickedLevel.worldY += ( m.worldY - origin.worldY );
			origin = m;
		}
	}

	function getLevelAt(worldX:Int, worldY:Int, allowSelf:Bool) {
		for(l in project.levels)
			if( worldX>=l.worldX && worldX<l.worldX+l.pxWid && worldY>=l.worldY && worldY<l.worldY+l.pxHei )
				if( !allowSelf || allowSelf && l!=editor.curLevel )
					return l;
		return null;
	}
}