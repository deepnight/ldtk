typedef SelectionBounds = { top:Int, left:Int, right:Int, bottom:Int }

class GenericLevelElementGroup {
	var editor(get,never): Editor; inline function get_editor() return Editor.ME;

	var renderWrapper : h2d.Object;
	var ghost : h2d.Graphics;
	var selectRender : h2d.Graphics;
	var arrow : h2d.Graphics;
	var pointLinks : h2d.Graphics;
	var elements : Array< Null<GenericLevelElement> > = [];
	var bounds(get,never) : SelectionBounds;
	var _cachedBounds : SelectionBounds;

	var invalidatedSelectRender = true;

	public function new(?elems:Array<GenericLevelElement>) {
		if( elems!=null )
			elements = elems.copy();

		renderWrapper = new h2d.Object();
		editor.levelRender.root.add(renderWrapper, Const.DP_UI);

		ghost = new h2d.Graphics(renderWrapper);

		arrow = new h2d.Graphics(renderWrapper);
		pointLinks = new h2d.Graphics(renderWrapper);
		selectRender = new h2d.Graphics(renderWrapper);
		selectRender.filter = new h2d.filter.Group([
			new dn.heaps.filter.PixelOutline(0xffcc00),
			new dn.heaps.filter.PixelOutline(0x0),
		]);
		invalidateBounds();
	}

	public function clear() {
		elements = [];
		clearGhost();
		invalidateBounds();
		invalidateSelectRender();
	}

	public function dispose() {
		renderWrapper.remove();
		_cachedBounds = null;
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
		invalidateBounds();
		invalidateSelectRender();
	}

	public function getSelectedLayerInstances() {
		var map = new Map();
		for(ge in elements)
			switch ge {
				case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
					map.set(li,li);
			}

		var lis = [];
		for(li in map)
			lis.push(li);
		return lis;
	}

	inline function invalidateSelectRender()  invalidatedSelectRender = true;
	inline function invalidateBounds()  _cachedBounds = null;

	function get_bounds() {
		if( _cachedBounds==null ) {
			if( elements.length==0 )
				_cachedBounds = { top:0, left:0, right:0, bottom:0 }
			else {
				_cachedBounds = {
					top : Const.INFINITE,
					left : Const.INFINITE,
					right : -Const.INFINITE,
					bottom : -Const.INFINITE,
				}

				for(e in elements) {
					var x = switch e {
						case IntGrid(li, cx, cy), Tile(li,cx,cy): li.pxOffsetX + cx*li.def.gridSize;
						case Entity(li, ei): li.pxOffsetX + ei.x;
						case PointField(li, ei, fi, arrayIdx):
							var pt = fi.getPointGrid(arrayIdx);
							if( pt!=null )
								li.pxOffsetX + pt.cx*li.def.gridSize;
							else 0; // HACK should not happen? Need checks
					}
					var y = switch e {
						case IntGrid(li, cx, cy), Tile(li,cx,cy): li.pxOffsetY + cy*li.def.gridSize;
						case Entity(li, ei): li.pxOffsetY +  ei.y;
						case PointField(li, ei, fi, arrayIdx):
							var pt = fi.getPointGrid(arrayIdx);
							if( pt!=null )
								li.pxOffsetY + pt.cy*li.def.gridSize;
							else 0; // HACK should not happen? Need checks
					}
					_cachedBounds.top = M.imin( _cachedBounds.top, y );
					_cachedBounds.bottom = M.imax( _cachedBounds.bottom, y );
					_cachedBounds.left = M.imin( _cachedBounds.left, x );
					_cachedBounds.right = M.imax( _cachedBounds.right, x );
				}
			}
		}
		return _cachedBounds;
	}

	function clearGhost() {
		pointLinks.clear();
		pointLinks.visible = false;

		arrow.clear();
		arrow.visible = false;

		ghost.visible = false;
		ghost.clear();
		ghost.removeChildren();
	}

	function renderSelection() {
		selectRender.clear();
		selectRender.visible = true;
		selectRender.beginFill(0xffcc00, 0.3);

		for(ge in elements) {
			switch ge {
				case null:
				case IntGrid(li, cx, cy), Tile(li, cx, cy):
					selectRender.drawRect(
						li.pxOffsetX + cx*li.def.gridSize,
						li.pxOffsetY + cy*li.def.gridSize,
						li.def.gridSize,
						li.def.gridSize
					);

				case Entity(li, ei):
					selectRender.drawRect(
						li.pxOffsetX + ei.x - ei.def.width * ei.def.pivotX,
						li.pxOffsetY + ei.y - ei.def.height * ei.def.pivotY,
						ei.def.width,
						ei.def.height
					);

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null )
						selectRender.drawCircle(
							li.pxOffsetX + (pt.cx+0.5)*li.def.gridSize,
							li.pxOffsetY + (pt.cy+0.5)*li.def.gridSize,
							li.def.gridSize*0.4
						);
			}
		}
	}

	function renderGhost() {
		clearGhost();

		for(ge in elements) {
			switch ge {
				case null:

				case IntGrid(li, cx, cy):
					ghost.lineStyle();
					ghost.beginFill( li.getIntGridColorAt(cx,cy) );
					ghost.drawRect(
						li.pxOffsetX + cx*li.def.gridSize - bounds.left,
						li.pxOffsetY + cy*li.def.gridSize - bounds.top,
						li.def.gridSize,
						li.def.gridSize
					);
					ghost.endFill();

				case Entity(li, ei):
					var e = display.LevelRender.createEntityRender(ei);
					ghost.addChild(e);
					e.alpha = 0.5;
					e.x = li.pxOffsetX + ei.x - bounds.left;
					e.y = li.pxOffsetY + ei.y - bounds.top;

				case Tile(li, cx, cy):
					var tid = li.getGridTile(cx,cy);
					var td = editor.project.defs.getTilesetDef( li.def.tilesetDefUid );
					var bmp = new h2d.Bitmap( td.getTile(tid), ghost );
					bmp.x = li.pxOffsetX + cx*li.def.gridSize - bounds.left;
					bmp.y = li.pxOffsetY + cy*li.def.gridSize - bounds.top;

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null ) {
						var x = li.pxOffsetX + (pt.cx+0.5)*li.def.gridSize - bounds.left;
						var y = li.pxOffsetY + (pt.cy+0.5)*li.def.gridSize - bounds.top;
						ghost.lineStyle(1, ei.getSmartColor(false));
						ghost.drawCircle(x, y, li.def.gridSize*0.5);

						ghost.lineStyle();
						ghost.beginFill(ei.getSmartColor(false) );
						ghost.drawCircle(x, y, li.def.gridSize*0.3);
						ghost.endFill();
					}
			}
		}

		return ghost;
	}

	function getDeltaX(origin:MouseCoords, now:MouseCoords) {
		return snapToGrid()
			? ( now.cx - origin.cx ) * getSmartSnapGrid()
			: now.levelX - origin.levelX;
	}

	function getDeltaY(origin:MouseCoords, now:MouseCoords) {
		return snapToGrid()
			? ( now.cy - origin.cy ) * getSmartSnapGrid()
			: now.levelY - origin.levelY;
	}

	public function getSmartRelativeLayerInstance() : Null<led.inst.LayerInstance> {
		var l : led.inst.LayerInstance = null;
		for(ge in elements)
			switch ge {
				case null:

				case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
					if( l==null || li.def.gridSize>l.def.gridSize )
						l = li;
			}
		return l;
	}

	inline function getSmartSnapGrid() {
		var li = getSmartRelativeLayerInstance();
		return li==null ? 1 : li.def.gridSize;
	}

	public function hasIncompatibleGridSizes() {
		var grid = getSmartSnapGrid();
		for( ge in elements )
			switch ge {
			case null:
			case IntGrid(li, _), Entity(li, _), Tile(li, _), PointField(li, _):
				if( li.def.gridSize<grid && grid % li.def.gridSize != 0 )
					return true;
			}

		return false;
	}

	function isEntitySelected(e:led.inst.EntityInstance) {
		for( ge in elements)
			switch ge {
				case Entity(li, ei):
					if( ei==e )
						return true;

				case _:
			}

		return false;
	}

	function isPointSelected(f:led.inst.FieldInstance, idx:Int) {
		for( ge in elements)
			switch ge {
				case PointField(li, ei, fi, arrayIdx):
					if( fi==f && arrayIdx==idx )
						return true;

				case _:
			}

		return false;
	}

	inline function levelToGhostX(v:Float) {
		return v - bounds.left + ghost.x;
	}

	inline function levelToGhostY(v:Float) {
		return v - bounds.top + ghost.y;
	}

	public function onMoveStart() {
		renderGhost();
	}

	public function onMoveEnd() {
		clearGhost();
		arrow.clear();
		arrow.visible = false;
	}

	public function showGhost(origin:MouseCoords, now:MouseCoords, isCopy:Bool) {
		var rel = getSmartRelativeLayerInstance();
		origin = origin.cloneRelativeToLayer(rel);
		now = now.cloneRelativeToLayer(rel);

		selectRender.visible = false;

		var offX = bounds.left - origin.levelX;
		var offY = bounds.top - origin.levelY;

		ghost.visible = true;
		ghost.x = offX + origin.levelX + getDeltaX(origin,now);
		ghost.y = offY + origin.levelY + getDeltaY(origin,now);


		// Movement arrow
		var onlyMovingPoints = true;
		for(ge in elements)
			if( !ge.match(PointField(_)) ) {
				onlyMovingPoints = false;
				break;
			}
		if( onlyMovingPoints || now.cx==origin.cx && now.cy==origin.cy )
			arrow.visible = false;
		else {
			var grid = getSmartSnapGrid();
			var fx = rel.pxOffsetX + (origin.cx+0.5) * grid;
			var fy = rel.pxOffsetY + (origin.cy+0.5) * grid;
			var tx = rel.pxOffsetX + (now.cx+0.5) * grid;
			var ty = rel.pxOffsetY + (now.cy+0.5) * grid;

			var a = Math.atan2(ty-fy, tx-fx);
			var size = 6;

			// Main line
			var c = isCopy ? 0xffcc00 : 0xffffff;
			arrow.clear();
			arrow.visible = true;
			arrow.lineStyle(1, c);
			if( !isCopy ) {
				arrow.moveTo(fx,fy);
				arrow.lineTo(tx,ty);
			}
			else {
				var d = 2;
				arrow.moveTo( fx+Math.cos(a+M.PIHALF)*d*0.5, fy+Math.sin(a+M.PIHALF)*d*0.5 );
				arrow.lineTo( tx+Math.cos(a+M.PIHALF)*d*0.5, ty+Math.sin(a+M.PIHALF)*d*0.5 );

				arrow.moveTo( fx+Math.cos(a-M.PIHALF)*d*0.5, fy+Math.sin(a-M.PIHALF)*d*0.5 );
				arrow.lineTo( tx+Math.cos(a-M.PIHALF)*d*0.5, ty+Math.sin(a-M.PIHALF)*d*0.5 );
			}

			// "Wings"
			arrow.lineStyle(2, c, 1);
			arrow.moveTo( tx, ty );
			arrow.lineTo( tx + Math.cos(a+M.PI*0.8)*size, ty + Math.sin(a+M.PI*0.8)*size );

			arrow.moveTo(tx,ty);
			arrow.lineTo( tx + Math.cos(a-M.PI*0.8)*size, ty + Math.sin(a-M.PI*0.8)*size );

			// Arrow peak fix
			arrow.beginFill(c);
			arrow.lineStyle();
			arrow.drawCircle(tx,ty,1,8);
			arrow.endFill();

		}


		// Render point links
		pointLinks.clear();
		pointLinks.visible = !isCopy;
		for(ge in elements)
			switch ge {
				case Entity(li,ei):
					for(fi in ei.fieldInstances) {
						if( fi.def.type!=F_Point )
							continue;

						if( fi.def.editorDisplayMode!=PointPath && fi.def.editorDisplayMode!=PointStar )
							continue;

						// Links to Entity own field points
						for( i in 0...fi.getArrayLength() ) {
							if( i>0 && fi.def.editorDisplayMode==PointPath )
								continue;

							pointLinks.lineStyle(1,ei.getSmartColor(true));
							pointLinks.moveTo( levelToGhostX(ei.x), levelToGhostY(ei.y) );
							var pt = fi.getPointGrid(i);
							if( pt!=null )
								if( isPointSelected(fi,i) ) {
									pointLinks.lineTo(
										levelToGhostX( li.pxOffsetX+(pt.cx+0.5)*li.def.gridSize ),
										levelToGhostY( li.pxOffsetY+(pt.cy+0.5)*li.def.gridSize )
									);
								}
								else
									pointLinks.lineTo(
										li.pxOffsetX+(pt.cx+0.5)*li.def.gridSize,
										li.pxOffsetY+(pt.cy+0.5)*li.def.gridSize
									);
						}
					}

				case PointField(li, ei, fi, arrayIdx):
					pointLinks.lineStyle(1,ei.getSmartColor(true));
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null ) {
						var x = levelToGhostX( li.pxOffsetX+(pt.cx+0.5)*li.def.gridSize );
						var y = levelToGhostY( li.pxOffsetY+(pt.cy+0.5)*li.def.gridSize );

						// Link to entity
						if( fi.def.editorDisplayMode==PointStar || arrayIdx==0 ) {
							pointLinks.moveTo(x,y);
							if( !isEntitySelected(ei) )
								pointLinks.lineTo(ei.x, ei.y);
							else
								pointLinks.lineTo( levelToGhostX(ei.x), levelToGhostY(ei.y) );
						}

						if( fi.def.editorDisplayMode==PointPath ) {
							// Link to previous point in path
							if( arrayIdx>0 ) {
								var prev = fi.getPointGrid(arrayIdx-1);
								if( prev!=null ) {
									pointLinks.moveTo(x,y);
									if( isPointSelected(fi,arrayIdx-1) )
										pointLinks.lineTo(
											levelToGhostX( li.pxOffsetX+(prev.cx+0.5)*li.def.gridSize ),
											levelToGhostY( li.pxOffsetY+(prev.cy+0.5)*li.def.gridSize )
										);
									else
										pointLinks.lineTo(
											li.pxOffsetX+(prev.cx+0.5)*li.def.gridSize,
											li.pxOffsetY+(prev.cy+0.5)*li.def.gridSize
										);
								}
							}

							// Link to next point in path
							if( arrayIdx<fi.getArrayLength()-1 ) {
								var next = fi.getPointGrid(arrayIdx+1);
								if( next!=null ) {
									pointLinks.moveTo(x,y);
									if( isPointSelected(fi,arrayIdx+1) )
										pointLinks.lineTo(
											levelToGhostX( li.pxOffsetX+(next.cx+0.5)*li.def.gridSize ),
											levelToGhostY( li.pxOffsetX+(next.cy+0.5)*li.def.gridSize )
										);
									else
										pointLinks.lineTo(
											li.pxOffsetX+(next.cx+0.5)*li.def.gridSize,
											li.pxOffsetY+(next.cy+0.5)*li.def.gridSize
										);
								}
							}
						}
					}

				case _:
			}
	}


	function snapToGrid() {
		return true;
	}


	public function moveSelecteds(origin:MouseCoords, to:MouseCoords, isCopy:Bool) : Bool {
		var rel = getSmartRelativeLayerInstance();
		origin = origin.cloneRelativeToLayer(rel);
		to = to.cloneRelativeToLayer(rel);

		if( elements.length==0 )
			return false;

		var anyChange = false;
		invalidateBounds();
		invalidateSelectRender();

		var removals : Array< Void->Void > = [];
		var inserts : Array< Void->Void > = [];
		var changedLayers : Map<led.inst.LayerInstance, led.inst.LayerInstance> = [];

		// Prepare movement effects
		var moveGrid = getSmartSnapGrid();
		var i = 0;
		for( ge in elements ) {
			switch ge {
				case null:

				case Entity(li, ei):
					var i = i;
					inserts.push( ()->{
						if( isCopy ) {
							ei = li.duplicateEntityInstance(ei);
							elements[i] = Entity(li,ei);
							if( ui.EntityInstanceEditor.isOpen() )
								ui.EntityInstanceEditor.openFor(ei);
						}
						ei.x += getDeltaX(origin, to);
						ei.y += getDeltaY(origin, to);
						editor.ge.emit( EntityInstanceChanged(ei) );

						// Remap points
						if( isCopy ) {
							var dcx = Std.int( getDeltaX(origin,to) / li.def.gridSize );
							var dcy = Std.int( getDeltaY(origin,to) / li.def.gridSize );
							for(fi in ei.fieldInstances)
								if( fi.def.type==F_Point )
									for( i in 0...fi.getArrayLength() ) {
										var pt = fi.getPointGrid(i);
										if( pt!=null ) {
											pt.cx+=dcx;
											pt.cy+=dcy;
											fi.parseValue(i, pt.cx+Const.POINT_SEPARATOR+pt.cy);
										}
									}
						}
					});
					anyChange = true;

				case IntGrid(li, cx,cy):
					var v = li.getIntGrid(cx,cy);
					var gridRatio = Std.int( moveGrid / li.def.gridSize );
					var tcx = cx + (to.cx-origin.cx)*gridRatio;
					var tcy = cy + (to.cy-origin.cy)*gridRatio;
					if( !isCopy )
						removals.push( ()-> li.removeIntGrid(cx,cy) );
					inserts.push( ()-> li.setIntGrid(tcx, tcy, v) );

					elements[i] = li.isValid(tcx,tcy) ? IntGrid(li, tcx, tcy) : null; // update selection

					changedLayers.set(li,li);
					anyChange = true;

				case Tile(li, cx,cy):
					var v = li.getGridTile(cx,cy);
					var gridRatio = Std.int( moveGrid / li.def.gridSize );
					var tcx = cx + (to.cx-origin.cx)*gridRatio;
					var tcy = cy + (to.cy-origin.cy)*gridRatio;
					if( !isCopy )
						removals.push( ()-> li.removeGridTile(cx,cy) );
					inserts.push( ()-> li.setGridTile(tcx, tcy, v) );

					elements[i] = li.isValid(tcx,tcy) ? Tile(li, tcx, tcy) : null; // update selection

					changedLayers.set(li,li);
					anyChange = true;

				case PointField(li, ei, fi, arrayIdx):
					if( isCopy )
						elements[i] = null;
					else {
						var pt = fi.getPointGrid(arrayIdx);
						inserts.push( ()-> {
							if( isCopy ) {
								N.debug("dup");
								fi.addArrayValue();
								var newIdx = fi.getArrayLength()-1;
								fi.parseValue( newIdx, fi.getPointStr(arrayIdx) );
								pt = fi.getPointGrid(newIdx);
								elements[i] = PointField(li,ei,fi,newIdx);
							}
							pt.cx += Std.int( getDeltaX(origin, to) / li.def.gridSize );
							pt.cy += Std.int( getDeltaY(origin, to) / li.def.gridSize );
							fi.parseValue(arrayIdx, pt.cx+Const.POINT_SEPARATOR+pt.cy);
							editor.ge.emit( EntityInstanceChanged(ei) );
						} );
						changedLayers.set(li,li);
						anyChange = true;
					}
			}
			i++;
		}

		// Execute move
		for(cb in removals) cb();
		for(cb in inserts) cb();

		// Call refresh events
		for(li in changedLayers) {
			editor.ge.emit( LayerInstanceChanged );
			editor.levelRender.invalidateLayer(li);
		}

		// Drop null selections
		var i = 0;
		while( i<elements.length )
			if( elements[i]==null )
				elements.splice(i,1);
			else
				i++;

		return anyChange;
	}


	public function deleteSelecteds() {
		for(ge in elements)
			switch ge {
				case null:

				case IntGrid(li, cx, cy):
					li.removeIntGrid(cx,cy);

				case Entity(li, ei):
					li.removeEntityInstance(ei);

				case Tile(li, cx, cy):
					li.removeGridTile(cx,cy);

				case PointField(li, ei, fi, arrayIdx):
					fi.removeArrayValue(arrayIdx);
			}

		clear();
	}

	public function onPostUpdate() {
		if( invalidatedSelectRender ) {
			invalidatedSelectRender = false;
			renderSelection();
		}
	}
}