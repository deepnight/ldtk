class GenericLevelElementGroup {
	public var elements : Array<GenericLevelElement> = [];

	public function new(?elems:Array<GenericLevelElement>) {
		if( elems!=null )
			elements = elems.copy();
	}

	public function getBoundsPx() {
		if( elements.length==0 )
			return null;

		var top = Const.INFINITE;
		var left = Const.INFINITE;
		var right = -Const.INFINITE;
		var bottom = -Const.INFINITE;

		for(e in elements) {
			var x = switch e {
				case IntGrid(li, cx, cy), Tile(li,cx,cy): li.pxOffsetX + cx*li.def.gridSize;
				case Entity(li, ei): li.pxOffsetX + ei.x;
				case PointField(li, ei, fi, arrayIdx): li.pxOffsetX + fi.getPointGrid(arrayIdx).cx*li.def.gridSize;
			}
			var y = switch e {
				case IntGrid(li, cx, cy), Tile(li,cx,cy): li.pxOffsetY + cy*li.def.gridSize;
				case Entity(li, ei): li.pxOffsetY +  ei.y;
				case PointField(li, ei, fi, arrayIdx): li.pxOffsetY + fi.getPointGrid(arrayIdx).cy*li.def.gridSize;
			}
			top = M.imin( top, y );
			bottom = M.imax( top, y );
			left = M.imin( left, x );
			right = M.imax( right, x );
		}

		return {
			top: top,
			right: right,
			bottom: bottom,
			left: left,
		}
	}
}