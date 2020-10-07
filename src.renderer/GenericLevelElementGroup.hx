class GenericLevelElementGroup {
	var editor(get,never): Editor; inline function get_editor() return Editor.ME;

	var renderWrapper : h2d.Object;
	var ghost : h2d.Graphics;
	var arrow : h2d.Graphics;
	var elements : Array<GenericLevelElement> = [];

	public function new(?elems:Array<GenericLevelElement>) {
		if( elems!=null )
			elements = elems.copy();

		renderWrapper = new h2d.Object();
		editor.levelRender.root.add(renderWrapper, Const.DP_UI);

		ghost = new h2d.Graphics(renderWrapper);
		arrow = new h2d.Graphics(renderWrapper);
	}

	public function clear() {
		elements = [];
		clearGhost();
	}

	public function dispose() {
		renderWrapper.remove();
		elements = null;
	}

	public inline function length() return elements.length;
	public inline function all() return elements;
	public inline function get(idx:Int) return elements[idx];

	public function add(ge:GenericLevelElement) {
		for(e in elements)
			if( ge.equals(e) )
				return;
		elements.push(ge);
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

	function clearGhost() {
		ghost.visible = false;
		ghost.clear();
		ghost.removeChildren();
	}

	function renderGhost(origin:MouseCoords) {
		clearGhost();

		var b = getBoundsPx();
		var offX = b.left - origin.levelX;
		var offY = b.top - origin.levelY;

		for(ge in elements) {
			switch ge {
				case IntGrid(li, cx, cy):
					ghost.beginFill( li.getIntGridColorAt(cx,cy) );
					ghost.drawRect(
						offX + li.pxOffsetX + cx*li.def.gridSize - b.left,
						offY + li.pxOffsetY + cy*li.def.gridSize - b.top,
						li.def.gridSize,
						li.def.gridSize
					);
					ghost.endFill();

				case Entity(li, ei):
					var e = display.LevelRender.createEntityRender(ei);
					ghost.addChild(e);
					e.alpha = 0.5;
					e.x = offX + ei.x - b.left;
					e.y = offY + ei.y - b.top;

				case Tile(li, cx, cy):
					var tid = li.getGridTile(cx,cy);
					var td = editor.project.defs.getTilesetDef( li.def.tilesetDefUid );
					var bmp = new h2d.Bitmap( td.getTile(tid), ghost );
					bmp.x = offX + li.pxOffsetX + cx*li.def.gridSize - b.left;
					bmp.y = offY + li.pxOffsetY + cy*li.def.gridSize - b.top;

				case PointField(li, ei, fi, arrayIdx):
			}
		}

		ghost.beginFill(0xffcc00);
		ghost.drawCircle(0,0,8);

		return ghost;
	}

	public inline function hideGhost() {
		clearGhost();
		arrow.clear();
		arrow.visible = false;
	}

	function getDeltaX(origin:MouseCoords, now:MouseCoords) {
		return snapToGrid()
			? ( now.cx - origin.cx ) * getSnapGrid()
			: now.levelX - origin.levelX;
	}

	function getDeltaY(origin:MouseCoords, now:MouseCoords) {
		return snapToGrid()
			? ( now.cy - origin.cy ) * getSnapGrid()
			: now.levelY - origin.levelY;
	}

	function getSnapGrid() {
		var grid = 0;
		for(ge in elements)
			switch ge {
				case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
					grid = M.imax( grid, li.def.gridSize );
			}
		return grid;
	}

	public function hasMixedGridSizes() {
		var grid = getSnapGrid();
		for( ge in elements )
			switch ge {
			case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
				if( li.def.gridSize!=grid )
					return true;
			}

		return false;
	}

	public function showGhost(origin:MouseCoords, now:MouseCoords) {
		if(! ghost.visible )
			renderGhost(origin);

		ghost.visible = true;
		ghost.x = origin.levelX + getDeltaX(origin,now);
		ghost.y = origin.levelY + getDeltaY(origin,now);

		// Render movement arrow
		arrow.clear();
		arrow.visible = true;
		var grid = getSnapGrid();
		var fx = (origin.cx+0.5) * grid;
		var fy = (origin.cy+0.5) * grid;
		var tx = (now.cx+0.5) * grid;
		var ty = (now.cy+0.5) * grid;

		var a = Math.atan2(ty-fy, tx-fx);
		var size = 10;
		arrow.lineStyle(1, 0xffffff, 1);
		arrow.moveTo(fx,fy);
		arrow.lineTo(tx,ty);

		arrow.moveTo(tx,ty);
		arrow.lineTo( tx + Math.cos(a+M.PI*0.8)*size, ty + Math.sin(a+M.PI*0.8)*size );

		arrow.moveTo(tx,ty);
		arrow.lineTo( tx + Math.cos(a-M.PI*0.8)*size, ty + Math.sin(a-M.PI*0.8)*size );

	}


	function snapToGrid() {
		return true; // TODO
	}


	public function move(origin:MouseCoords, to:MouseCoords) : Bool {
		if( elements.length==0 )
			return false;

		var anyChange = false;

		var removals : Array< Void->Void > = [];
		var inserts : Array< Void->Void > = [];
		var changedLayers : Map<led.inst.LayerInstance, led.inst.LayerInstance> = [];

		var i = 0;
		for( ge in elements ) {
			switch ge {
				case Entity(li, ei):
					inserts.push( ()->{
						ei.x += getDeltaX(origin, to);
						ei.y += getDeltaY(origin, to);
						editor.ge.emit( EntityInstanceChanged(ei) );
					});
					anyChange = true;

				case IntGrid(li, cx,cy):
					var v = li.getIntGrid(cx,cy);
					removals.push( ()-> li.removeIntGrid(cx,cy) );
					inserts.push( ()-> li.setIntGrid(cx + to.cx-origin.cx, cy + to.cy-origin.cy, v) );
					elements[i] = IntGrid(li, cx + to.cx-origin.cx, cy + to.cy-origin.cy); // remap selection
					changedLayers.set(li,li);
					anyChange = true;

				case Tile(li, cx,cy):
					var v = li.getGridTile(cx,cy);
					removals.push( ()-> li.removeGridTile(cx,cy) );
					inserts.push( ()-> li.setGridTile(cx + to.cx-origin.cx, cy + to.cy-origin.cy, v) );
					elements[i] = Tile(li, cx + to.cx-origin.cx, cy + to.cy-origin.cy); // remap selection
					changedLayers.set(li,li);
					anyChange = true;

				case _: // HACK

				// case PointField(li, ei, fi, arrayIdx):
				// 	if( !isOnStop ) {
				// 		var old = fi.getPointStr(arrayIdx);
				// 		fi.parseValue(arrayIdx, m.cx+Const.POINT_SEPARATOR+m.cy);

				// 		var changed = old!=fi.getPointStr(arrayIdx);
				// 		if( changed )
				// 			editor.ge.emit( EntityInstanceChanged(ei) );
				// 		anyChange = anyChange || changed;
				// 	}
				// 	else
				// 		selectValue( new GenericLevelElementGroup([ PointField(li,ei,fi,arrayIdx) ]) );

				// case Tile(li,cx,cy):
				// 	if( isOnStop ) {
				// 		editor.curLevelHistory.markChange(m.cx,m.cy);
				// 		var v = li.getGridTile(cx,cy);
				// 		if( !isCopy )
				// 			li.removeGridTile(cx,cy);
				// 		li.setGridTile(m.cx, m.cy, v);
				// 		editor.selectionTool.selectValue( new GenericLevelElementGroup([ Tile(li, m.cx, m.cy) ]) );
				// 		anyChange = true;
				// 	}
			}
			i++;
		}

		for(cb in removals) cb();
		for(cb in inserts) cb();
		for(li in changedLayers) {
			editor.ge.emit( LayerInstanceChanged );
			editor.levelRender.invalidateLayer(li);
		}

		return anyChange;
	}

}