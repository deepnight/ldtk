typedef SelectionBounds = { top:Float, left:Float, right:Float, bottom:Float }

class GenericLevelElementGroup {
	static var SELECTION_COLOR = 0xffcc00;
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

	var originalRects : Array< { leftPx:Float, rightPx:Float, topPx:Float, bottomPx:Float } > = [];

	public function new(?elems:Array<GenericLevelElement>) {
		if( elems!=null )
			elements = elems.copy();

		renderWrapper = new h2d.Object();
		editor.levelRender.root.add(renderWrapper, Const.DP_UI);

		ghost = new h2d.Graphics(renderWrapper);

		arrow = new h2d.Graphics(renderWrapper);
		pointLinks = new h2d.Graphics(renderWrapper);
		selectRender = new h2d.Graphics(renderWrapper);
		var f = new dn.heaps.filter.PixelOutline(SELECTION_COLOR);
		f.setPartialKnockout(0.66);
		selectRender.filter = new h2d.filter.Group([
			f, new dn.heaps.filter.PixelOutline(0x0),
		]);
		invalidateBounds();
	}

	@:keep
	public function toString() {
		return elements.length==0 ? "empty" : elements.map( e->e.getName() ).slice(0,10).join(",");
	}

	public function clear() {
		elements = [];
		originalRects = [];
		clearGhost();
		invalidateBounds();
		invalidateSelectRender();
	}

	public function dispose() {
		renderWrapper.remove();
		originalRects = null;
		_cachedBounds = null;
		elements = null;
	}

	public inline function isEmpty() return elements.length==0 && originalRects.length==0;
	public inline function selectedElementsCount() return elements.length;
	public inline function allElements() return elements;
	public inline function getElement(idx:Int) return elements[idx];

	public function add(ge:GenericLevelElement) {
		// Already in selection?
		for(e in elements)
			if( ge.equals(e) )
				return false;

		// Add
		elements.push(ge);
		invalidateBounds();
		invalidateSelectRender();
		return true;
	}

	public function addSelectionRect(l,r,t,b) {
		originalRects.push({
			leftPx: M.imax(l, 0),
			rightPx: M.imin(r, editor.curLevel.pxWid),
			topPx: M.imax(t, 0),
			bottomPx: M.imin(b, editor.curLevel.pxHei),
		});

		// Discard rectangles included in other ones
		var i = 0;
		while( i<originalRects.length ) {
			var a = originalRects[i];

			var j = 0;
			while( j<originalRects.length ) {
				if( j!=i ) {
					var b = originalRects[j];
					if( b.leftPx>=a.leftPx && b.rightPx<=a.rightPx && b.topPx>=a.topPx && b.bottomPx<=a.bottomPx ) {
						originalRects.splice(j,1);
						j--;
					}
				}
				j++;
			}

			i++;
		}

		invalidateBounds();
		invalidateSelectRender();
	}

	public function getSelectedLayerInstances() {
		var map = new Map();
		for(ge in elements)
			switch ge {
				case GridCell(li, _), Entity(li, _), PointField(li, _):
					map.set(li,li);
			}

		var lis = [];
		for(li in map)
			lis.push(li);
		return lis;
	}

	public inline function invalidateSelectRender()  invalidatedSelectRender = true;
	public inline function invalidateBounds()  _cachedBounds = null;

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
						case GridCell(li, cx, cy): li.pxParallaxX + cx*li.def.scaledGridSize;
						case Entity(li, ei): li.pxParallaxX + ei.x*li.def.getScale();
						case PointField(li, ei, fi, arrayIdx):
							var pt = fi.getPointGrid(arrayIdx);
							if( pt!=null )
								li.pxParallaxX + pt.cx*li.def.scaledGridSize;
							else
								0;
					}
					var y = switch e {
						case GridCell(li, cx, cy): li.pxParallaxY + cy*li.def.scaledGridSize;
						case Entity(li, ei): li.pxParallaxY + ei.y*li.def.getScale();
						case PointField(li, ei, fi, arrayIdx):
							var pt = fi.getPointGrid(arrayIdx);
							if( pt!=null )
								li.pxParallaxY + pt.cy*li.def.scaledGridSize;
							else
								0;
					}
					_cachedBounds.top = M.fmin( _cachedBounds.top, y );
					_cachedBounds.bottom = M.fmax( _cachedBounds.bottom, y );
					_cachedBounds.left = M.fmin( _cachedBounds.left, x );
					_cachedBounds.right = M.fmax( _cachedBounds.right, x );

					for(r in originalRects) {
						_cachedBounds.top = M.fmin( _cachedBounds.top, r.topPx );
						_cachedBounds.bottom = M.fmax( _cachedBounds.bottom, r.bottomPx );
						_cachedBounds.left = M.fmin( _cachedBounds.left, r.leftPx );
						_cachedBounds.right = M.fmax( _cachedBounds.right, r.rightPx );
					}

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
		var c = SELECTION_COLOR;
		var alpha = 1;

		for(r in originalRects) {
			selectRender.beginFill(0x8ab7ff, alpha);
			selectRender.drawRect(r.leftPx, r.topPx, r.rightPx-r.leftPx, r.bottomPx-r.topPx);
		}

		for(ge in elements) {
			switch ge {
				case null:
				case GridCell(li, cx, cy):
					if( li.hasAnyGridValue(cx,cy) )
						selectRender.beginFill(c, alpha);
					else
						selectRender.beginFill(0x8ab7ff, alpha*0.6);
					selectRender.drawRect(
						li.pxParallaxX + cx*li.def.scaledGridSize,
						li.pxParallaxY + cy*li.def.scaledGridSize,
						li.def.scaledGridSize,
						li.def.scaledGridSize
					);

				case Entity(li, ei):
					selectRender.beginFill(c, alpha);
					selectRender.drawRect(
						li.pxParallaxX + ( ei.x - ei.width * ei.def.pivotX ) * li.def.getScale(),
						li.pxParallaxY + ( ei.y - ei.height * ei.def.pivotY ) * li.def.getScale(),
						ei.width * li.def.getScale(),
						ei.height * li.def.getScale()
					);

				case PointField(li, ei, fi, arrayIdx):
					selectRender.beginFill(c, alpha);
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null )
						selectRender.drawCircle(
							li.pxParallaxX + (pt.cx+0.5)*li.def.scaledGridSize,
							li.pxParallaxY + (pt.cy+0.5)*li.def.scaledGridSize,
							li.def.scaledGridSize*0.4
						);
			}
		}
	}

	function renderGhost() {
		clearGhost();

		for(ge in elements) {
			switch ge {
				case null:

				case GridCell(li, cx, cy):
					if( li.hasAnyGridValue(cx,cy) )
						switch li.def.type {
							case IntGrid:
								ghost.lineStyle();
								ghost.beginFill( li.getIntGridColorAt(cx,cy) );
								ghost.drawRect(
									li.pxParallaxX + cx*li.def.scaledGridSize - bounds.left,
									li.pxParallaxY + cy*li.def.scaledGridSize - bounds.top,
									li.def.scaledGridSize,
									li.def.scaledGridSize
								);
								ghost.endFill();

							case Tiles:
								var td = li.getTilesetDef();
								if( td!=null && td.isAtlasLoaded() )
									for( t in li.getGridTileStack(cx,cy) ) {
										var bmp = new h2d.Bitmap( td.getTileById(t.tileId), ghost );
										bmp.x = li.pxParallaxX + ( cx + (M.hasBit(t.flips,0)?1:0) ) * li.def.scaledGridSize - bounds.left;
										bmp.y = li.pxParallaxY + ( cy + (M.hasBit(t.flips,1)?1:0) ) * li.def.scaledGridSize - bounds.top;
										bmp.scaleX = M.hasBit(t.flips, 0) ? -1 : 1;
										bmp.scaleY = M.hasBit(t.flips, 1) ? -1 : 1;
									}

							case Entities:
							case AutoLayer:
						}

				case Entity(li, ei):
					var core = display.EntityRender.renderCore(ei);
					ghost.addChild(core.wrapper);
					core.wrapper.alpha = 0.5;
					core.wrapper.x = li.pxParallaxX + ei.x - bounds.left;
					core.wrapper.y = li.pxParallaxY + ei.y - bounds.top;

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null ) {
						var x = li.pxParallaxX + (pt.cx+0.5)*li.def.scaledGridSize - bounds.left;
						var y = li.pxParallaxY + (pt.cy+0.5)*li.def.scaledGridSize - bounds.top;
						ghost.lineStyle(1, ei.getSmartColor(false));
						ghost.drawCircle(x, y, li.def.scaledGridSize*0.5);

						ghost.lineStyle();
						ghost.beginFill(ei.getSmartColor(false) );
						ghost.drawCircle(x, y, li.def.scaledGridSize*0.3);
						ghost.endFill();
					}
			}
		}

		ghost.endFill();
		for(r in originalRects) {
			ghost.lineStyle(1,SELECTION_COLOR,0.5);
			ghost.drawRect(r.leftPx-bounds.left, r.topPx-bounds.top, r.rightPx-r.leftPx, r.bottomPx-r.topPx);
		}

		return ghost;
	}

	function getDeltaX(origin:Coords, now:Coords) {
		return snapToGrid()
			? ( now.cx - origin.cx ) * getSmartSnapGrid()
			: now.levelX - origin.levelX;
	}

	function getDeltaY(origin:Coords, now:Coords) {
		return snapToGrid()
			? ( now.cy - origin.cy ) * getSmartSnapGrid()
			: now.levelY - origin.levelY;
	}

	public function getSmartRelativeLayerInstance() : Null<data.inst.LayerInstance> {
		var l : data.inst.LayerInstance = null;
		for(ge in elements)
			switch ge {
				case null:

				case GridCell(li, _), Entity(li, _), PointField(li, _):
					if( l==null || li.def.scaledGridSize>l.def.scaledGridSize )
						l = li;
			}
		return l;
	}

	inline function getSmartSnapGrid() {
		var li = getSmartRelativeLayerInstance();
		return li==null ? 1 : li.def.scaledGridSize;
	}

	public function hasIncompatibleGridSizes() {
		var li  = getSmartRelativeLayerInstance();
		var grid = li==null ? 1 : li.def.gridSize;
		for( ge in elements )
			switch ge {
			case null:
			case GridCell(li, _), Entity(li, _), PointField(li, _):
				if( li.def.gridSize<grid && grid % li.def.gridSize != 0 )
					return true;
			}

		return false;
	}

	function isEntitySelected(e:data.inst.EntityInstance) {
		for( ge in elements)
			switch ge {
				case Entity(li, ei):
					if( ei==e )
						return true;

				case _:
			}

		return false;
	}

	function isFieldValueSelected(f:data.inst.FieldInstance, idx:Int) {
		return getFieldValueSelectionIdx(f,idx) >= 0;
	}

	function getFieldValueSelectionIdx(f:data.inst.FieldInstance, idx:Int) : Int {
		for( i in 0...elements.length )
			switch elements[i] {
				case PointField(li, ei, fi, arrayIdx):
					if( fi==f && arrayIdx==idx )
						return i;

				case _:
			}

		return -1;
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

	public function showGhost(origin:Coords, now:Coords, isCopy:Bool) {
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
			var fx = rel.pxParallaxX + (origin.cx+0.5) * grid;
			var fy = rel.pxParallaxY + (origin.cy+0.5) * grid;
			var tx = rel.pxParallaxX + (now.cx+0.5) * grid;
			var ty = rel.pxParallaxY + (now.cy+0.5) * grid;

			var a = Math.atan2(ty-fy, tx-fx);
			var size = 6;

			// Main line
			var c = isCopy ? SELECTION_COLOR : 0xffffff;
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
					for(fi in ei.getFieldInstancesOfType(F_Point)) {
						switch fi.def.editorDisplayMode {
							case PointStar, PointPath, PointPathLoop:
							case RefLinkBetweenCenters: continue;
							case RefLinkBetweenPivots: continue;
							case Points: continue;
							case EntityTile, LevelTile: continue;
							case Hidden, ValueOnly, NameAndValue, ArrayCountNoLabel, ArrayCountWithLabel, RadiusPx, RadiusGrid: continue;
						}

						// Links to Entity own field points
						for( i in 0...fi.getArrayLength() ) {
							if( i>0 && fi.def.editorDisplayMode==PointPath )
								continue;

							pointLinks.lineStyle(1,ei.getSmartColor(true));
							pointLinks.moveTo(
								levelToGhostX(ei.getPointOriginX(li.def)),
								levelToGhostY(ei.getPointOriginY(li.def))
							);
							var pt = fi.getPointGrid(i);
							if( pt!=null )
								if( isFieldValueSelected(fi,i) ) {
									pointLinks.lineTo(
										levelToGhostX( li.pxParallaxX+(pt.cx+0.5)*li.def.scaledGridSize ),
										levelToGhostY( li.pxParallaxY+(pt.cy+0.5)*li.def.scaledGridSize )
									);
								}
								else
									pointLinks.lineTo(
										li.pxParallaxX+(pt.cx+0.5)*li.def.scaledGridSize,
										li.pxParallaxY+(pt.cy+0.5)*li.def.scaledGridSize
									);
						}
					}

				case PointField(li, ei, fi, arrayIdx):
					pointLinks.lineStyle(1,ei.getSmartColor(true));
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null ) {
						var x = levelToGhostX( li.pxParallaxX+(pt.cx+0.5)*li.def.scaledGridSize );
						var y = levelToGhostY( li.pxParallaxY+(pt.cy+0.5)*li.def.scaledGridSize );

						// Link to entity
						if( fi.def.editorDisplayMode==PointStar || arrayIdx==0 ) {
							pointLinks.moveTo(x,y);
							if( !isEntitySelected(ei) )
								pointLinks.lineTo(ei.getPointOriginX(li.def), ei.getPointOriginY(li.def));
							else
								pointLinks.lineTo(
									levelToGhostX(ei.getPointOriginX(li.def)),
									levelToGhostY(ei.getPointOriginY(li.def))
								);
						}

						if( fi.def.editorDisplayMode==PointPath ) {
							// Link to previous point in path
							if( arrayIdx>0 ) {
								var prev = fi.getPointGrid(arrayIdx-1);
								if( prev!=null ) {
									pointLinks.moveTo(x,y);
									if( isFieldValueSelected(fi,arrayIdx-1) )
										pointLinks.lineTo(
											levelToGhostX( li.pxParallaxX+(prev.cx+0.5)*li.def.scaledGridSize ),
											levelToGhostY( li.pxParallaxX+(prev.cy+0.5)*li.def.scaledGridSize )
										);
									else
										pointLinks.lineTo(
											li.pxParallaxX+(prev.cx+0.5)*li.def.scaledGridSize,
											li.pxParallaxY+(prev.cy+0.5)*li.def.scaledGridSize
										);
								}
							}

							// Link to next point in path
							if( arrayIdx<fi.getArrayLength()-1 ) {
								var next = fi.getPointGrid(arrayIdx+1);
								if( next!=null ) {
									pointLinks.moveTo(x,y);
									if( isFieldValueSelected(fi,arrayIdx+1) )
										pointLinks.lineTo(
											levelToGhostX( li.pxParallaxX+(next.cx+0.5)*li.def.scaledGridSize ),
											levelToGhostY( li.pxParallaxX+(next.cy+0.5)*li.def.scaledGridSize )
										);
									else
										pointLinks.lineTo(
											li.pxParallaxX+(next.cx+0.5)*li.def.scaledGridSize,
											li.pxParallaxY+(next.cy+0.5)*li.def.scaledGridSize
										);
								}
							}
						}
					}

				case _:
			}
	}


	public function isOveringSelection(m:Coords) {
		for(ge in elements) {
			switch ge {
				case GridCell(li, cx, cy):
					if( m.getLayerCx(li)==cx && m.getLayerCy(li)==cy )
						return true;

				case Entity(li, ei):
					if( ei.isOver(m.layerX, m.layerY) )
						return true;

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null && m.getLayerCx(li)==pt.cx && m.getLayerCy(li)==pt.cy )
						return true;
			}
		}

		for(r in originalRects)
			if( m.levelX>=r.leftPx && m.levelX<=r.rightPx && m.levelY>=r.topPx && m.levelY<=r.bottomPx )
				return true;

		return false;
	}


	function snapToGrid() {
		return true;
	}


	/**
		Move or duplicate the selection
	**/
	public function moveSelecteds(origin:Coords, to:Coords, isCopy:Bool) : Array<data.inst.LayerInstance> {
		if( elements.length==0 )
			return [];

		var rel = getSmartRelativeLayerInstance();
		origin = origin.cloneRelativeToLayer(rel);
		to = to.cloneRelativeToLayer(rel);

		invalidateBounds();
		invalidateSelectRender();

		var postRemovals : Array< Void->Void > = [];
		var postInserts : Array< Void->Void > = [];
		var changedLayers : Map<data.inst.LayerInstance, data.inst.LayerInstance> = [];

		// Clear arrival to emulate "empty cell selection" mode
		if( originalRects.length>0 ) {
			for(r in originalRects) {
				r.leftPx += getDeltaX(origin,to);
				r.rightPx += getDeltaX(origin,to);
				r.topPx += getDeltaY(origin,to);
				r.bottomPx += getDeltaY(origin,to);
			}

			var layers = App.ME.settings.v.singleLayerMode
				? [ editor.curLayerInstance ]
				: editor.curLevel.layerInstances;
			for(li in layers)
				if( editor.levelRender.isLayerVisible(li) && ( li.def.type==IntGrid || li.def.type==Tiles ) ) {
					for(r in originalRects) {
						for(cx in li.levelToLayerCx(r.leftPx)...li.levelToLayerCx(r.rightPx+1))
						for(cy in li.levelToLayerCy(r.topPx)...li.levelToLayerCy(r.bottomPx+1)) {
							if( li.def.type==IntGrid )
								postRemovals.push( li.removeIntGrid.bind(cx,cy,false) );

							if( li.def.type==Tiles )
								postRemovals.push( li.removeAllGridTiles.bind(cx,cy,false) );
						}
					}
					changedLayers.set(li,li);
				}
		}

		// Prepare movement effects
		var outOfBoundsRemovals : Array<String> = [];
		var moveGrid = getSmartSnapGrid();
		for( i in 0...elements.length ) {
			var ge = elements[i];
			switch ge {
				case null:

				case Entity(li, ei):
					var i = i;

					// Duplicate entity
					if( isCopy ) {
						var ed = ei.def;
						var oldEi = ei;
						var newEi : data.inst.EntityInstance = null;

						// Check limits
						if( ed.maxCount<=0 )
							newEi = li.duplicateEntityInstance(ei);
						else {
							var all = ei._project.getAllEntitiesFromLimitScope(li, ed, ed.limitScope);
							switch ed.limitBehavior {
								case DiscardOldOnes:
									if( all.length>=ed.maxCount )
										N.error(L.t._("You cannot have more than ::n:: ::name::.", { n:ed.maxCount, name:ed.identifier }));
									else
										newEi = li.duplicateEntityInstance(ei);

								case PreventAdding:
									if( all.length>=ed.maxCount )
										N.error(L.t._("You cannot have more than ::n:: ::name::.", { n:ed.maxCount, name:ed.identifier }));
									else
										newEi = li.duplicateEntityInstance(ei);

								case MoveLastOne:
									if( all.length>=ed.maxCount )
										N.error(L.t._("You cannot have more than ::n:: ::name::.", { n:ed.maxCount, name:ed.identifier }));
									else
										newEi = li.duplicateEntityInstance(ei);
							}
						}

						// Allow duplication
						if( newEi!=null ) {
							elements[i] = Entity(li,newEi);

							if( editor.resizeTool!=null && editor.resizeTool.isOnEntity(oldEi) )
								editor.createResizeToolFor( Entity(li,newEi) );

							if( ui.EntityInstanceEditor.existsFor(oldEi) )
								ui.EntityInstanceEditor.openFor(newEi);

							ei = newEi;
						}
					}

					// Apply movement
					ei.x += Std.int( getDeltaX(origin, to) );
					ei.y += Std.int( getDeltaY(origin, to) );
					changedLayers.set(li,li);

					// Out of bounds
					if( !ei.def.allowOutOfBounds && ei.isOutOfLayerBounds() ) {
						outOfBoundsRemovals.push(ei.def.identifier);
						li.removeEntityInstance(ei);
						elements[i] = null;

						// Unselect lost entity points
						for(fi in ei.fieldInstances)
						for(i in 0...fi.getArrayLength()) {
							var selIdx = getFieldValueSelectionIdx(fi,i);
							elements[selIdx] = null;
						}

						editor.ge.emit( EntityInstanceRemoved(ei) );
					}
					else
						editor.ge.emit( EntityInstanceChanged(ei) );

					editor.curLevelTimeline.markEntityChange(ei);

					// Remap points
					if( isCopy ) {
						var dcx = Std.int( getDeltaX(origin,to) / li.def.scaledGridSize );
						var dcy = Std.int( getDeltaY(origin,to) / li.def.scaledGridSize );

						for(fi in ei.getFieldInstancesOfType(F_Point))
						for( i in 0...fi.getArrayLength() ) {
							var pt = fi.getPointGrid(i);
							if( pt!=null ) {
								pt.cx+=dcx;
								pt.cy+=dcy;
								fi.parseValue(i, pt.cx+Const.POINT_SEPARATOR+pt.cy);
							}
						}
					}

				case GridCell(li, cx,cy):
					if( li.hasAnyGridValue(cx,cy) ) {
						editor.curLevelTimeline.markGridChange(li, cx,cy);
						switch li.def.type {
							case IntGrid:
								var v = li.getIntGrid(cx,cy);
								var gridRatio = Std.int( moveGrid / li.def.scaledGridSize );
								var tcx = cx + (to.cx-origin.cx)*gridRatio;
								var tcy = cy + (to.cy-origin.cy)*gridRatio;
								if( !isCopy && li.hasIntGrid(cx,cy) )
									postRemovals.push( ()-> li.removeIntGrid(cx,cy,false) );
								postInserts.push( ()-> li.setIntGrid(tcx, tcy, v, false) );

								elements[i] = li.isValid(tcx,tcy) ? GridCell(li, tcx, tcy) : null; // update selection
								changedLayers.set(li,li);
								editor.curLevelTimeline.markGridChange(li, tcx,tcy);

							case Tiles:
								var gridRatio = Std.int( moveGrid / li.def.scaledGridSize );
								var tcx = cx + (to.cx-origin.cx)*gridRatio;
								var tcy = cy + (to.cy-origin.cy)*gridRatio;

								if( !isCopy && li.hasAnyGridTile(cx,cy) )
									postRemovals.push( ()-> li.removeAllGridTiles(cx,cy,false) );

								var stacking = li.getGridTileStack(cx,cy).length>1 || App.ME.settings.v.tileStacking;
								for( t in li.getGridTileStack(cx,cy) )
									postInserts.push( ()-> li.addGridTile(tcx, tcy, t.tileId, t.flips, stacking, false) );

								elements[i] = li.isValid(tcx,tcy) ? GridCell(li, tcx, tcy) : null; // update selection
								changedLayers.set(li,li);
								editor.curLevelTimeline.markGridChange(li, tcx,tcy);

							case Entities:
							case AutoLayer:
						}
					}

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					if( pt!=null ) {
						// Duplicate (only arrays)
						if( isCopy && fi.def.isArray ) {
							fi.addArrayValue();
							var i = fi.getArrayLength()-1;
							while( i>arrayIdx ) {
								fi.parseValue(i, fi.getPointStr(i-1));
								i--;
							}
						}

						// Move point
						pt.cx += Std.int( getDeltaX(origin, to) / li.def.scaledGridSize );
						pt.cy += Std.int( getDeltaY(origin, to) / li.def.scaledGridSize );

						if( li.isValid(pt.cx,pt.cy) )
							fi.parseValue(arrayIdx, pt.cx+Const.POINT_SEPARATOR+pt.cy);
						else {
							// Out of bounds
							outOfBoundsRemovals.push(fi.def.identifier);
							fi.removeArrayValue(arrayIdx);
							decrementAllFieldArrayIdxAbove(fi, arrayIdx);
							elements[i] = null;
						}

						editor.ge.emit( EntityInstanceChanged(ei) );
						changedLayers.set(li,li);
					}
			}
		}

		if( outOfBoundsRemovals.length>0 )
			N.warning( L.t._("Out-of-bounds entity removed: ::names::", {names:outOfBoundsRemovals.join(", ")}) );

		// Execute move
		for(cb in postRemovals) cb();
		for(cb in postInserts) cb();

		// Call refresh events
		var affectedLayers = [];
		for(li in changedLayers) {
			editor.ge.emit( LayerInstanceChangedGlobally(li) );
			editor.levelRender.invalidateLayer(li);
			affectedLayers.push(li);
		}

		// Grabage collect "null" selections
		var i = 0;
		while( i<elements.length )
			if( elements[i]==null )
				elements.splice(i,1);
			else
				i++;

		return affectedLayers;
	}


	@:allow(tool.SelectionTool)
	function decrementAllFieldArrayIdxAbove(f:data.inst.FieldInstance, above:Int) {
		for(i in 0...elements.length)
			switch elements[i] {
				case PointField(li, ei, fi, arrayIdx):
					if( fi==f && arrayIdx>=above )
						elements[i] = PointField(li,ei,fi,arrayIdx-1);

				case _:
			}
	}

	public function onPostUpdate() {
		if( invalidatedSelectRender ) {
			invalidatedSelectRender = false;
			renderSelection();
		}
	}
}