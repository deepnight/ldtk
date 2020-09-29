package tool;

class EntityTool extends Tool<Int> {
	public var curEntityDef(get,never) : Null<led.def.EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.defs.entities.length>0 )
			selectValue( project.defs.entities[0].uid );
	}

	inline function get_curEntityDef() return project.defs.getEntityDef(getSelectedValue());

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function canEdit():Bool {
		return super.canEdit() && getSelectedValue()>=0;
	}

	override function isPicking(m:MouseCoords):Bool {
		var e = editor.getGenericLevelElementAt(m, curLayerInstance);
		if( e!=null )
			return true;
		else
			return super.isPicking(m);
	}

	override function getDefaultValue():Int{
		if( project.defs.entities.length>0 )
			return project.defs.entities[0].uid;
		else
			return -1;
	}

	function getPlacementX(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayerInstance.def.gridSize )
			: m.levelX;
	}

	function getPlacementY(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayerInstance.def.gridSize )
			: m.levelY;
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( curEntityDef==null )
			editor.cursor.set(None);
		else if( isRunning() && curMode==Remove )
			editor.cursor.set( Eraser(m.levelX,m.levelY) );
		else if( curLevel.inBounds(m.levelX, m.levelY) )
			editor.cursor.set( Entity(curLayerInstance, curEntityDef, getPlacementX(m), getPlacementY(m)) );
		else
			editor.cursor.set(None);
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		switch curMode {
			case null, PanView:
			case Add:
				if( curLevel.inBounds(m.levelX, m.levelY) ) {
					var ei = curLayerInstance.createEntityInstance(curEntityDef);
					if( ei==null )
						N.error("Max per level reached!");
					else {
						ei.x = getPlacementX(m);
						ei.y = getPlacementY(m);
						editor.setSelection( Entity(curLayerInstance, ei) );
						onEditAnything();
						curMode = Move;
						editor.ge.emit( EntityInstanceAdded(ei) );
					}
				}

			case Remove:
				removeAnyEntityOrPointAt(m);

			case Move:
		}
	}


	function removeAnyEntityOrPointAt(m:MouseCoords) {
		var ge = editor.getGenericLevelElementAt(m, curLayerInstance);
		switch ge {
			case Entity(curLayerInstance, instance):
				curLayerInstance.removeEntityInstance(instance);
				editor.ge.emit( EntityInstanceRemoved(instance) );
				return true;

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				if( pt!=null && pt.cx==m.cx && pt.cy==m.cy ) {
					if( fi.def.isArray )
						fi.removeArrayValue(arrayIdx);
					else
						fi.parseValue(arrayIdx, null);
					editor.ge.emit( EntityInstanceFieldChanged(ei) );
					editor.setSelection( GenericLevelElement.Entity(li,ei) );
					return true;
				}
				else
					return false;

			case _:
		}

		return false;
	}


	function getPickedEntityInstance() : Null<led.inst.EntityInstance> {
		switch editor.selection {
			case null, IntGrid(_), Tile(_):
				return null;

			case PointField(li, ei, fi, arrayIdx):
				return ei;

			case Entity(curLayerInstance, instance):
				return instance;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null, PanView:
			case Add:

			case Remove:
				if( removeAnyEntityOrPointAt(m) )
					return true;

			case Move:
				if( moveStarted ) {
					switch editor.selection {
						case Entity(li, instance):
							var ei = getPickedEntityInstance();
							var oldX = ei.x;
							var oldY = ei.y;
							ei.x = getPlacementX(m);
							ei.y = getPlacementY(m);
							var changed = oldX!=ei.x || oldY!=ei.y;
							if( changed ) {
								editor.setSelection( Entity(curLayerInstance, ei) );
								editor.ge.emit( EntityInstanceChanged(ei) );
							}

							return changed;

						case PointField(li, ei, fi, arrayIdx):
							var old = fi.getPointStr(arrayIdx);
							fi.parseValue(arrayIdx, m.cx+Const.POINT_SEPARATOR+m.cy);

							var changed = old!=fi.getPointStr(arrayIdx);
							if( changed ) {
								editor.setSelection( PointField(li,ei,fi,arrayIdx) );
								editor.ge.emit( EntityInstanceChanged(ei) );
							}
							return changed;

						case _:
					}
				}
		}

		return false;
	}

	override function onHistorySaving() {
		super.onHistorySaving();

		if( curMode==Move ) {
			var ei = getPickedEntityInstance();
			if( ei!=null )
				editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
		}
	}


	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);
		return false;
		// editor.ge.emit(LayerInstanceChanged);
	}


	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.EntityPalette(this);
	}
}