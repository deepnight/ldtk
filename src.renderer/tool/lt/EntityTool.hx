package tool.lt;

class EntityTool extends tool.LayerTool<Int> {
	public var curEntityDef(get,never) : Null<data.def.EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.defs.entities.length>0 )
			selectValue( project.defs.entities[0].uid );
	}

	inline function get_curEntityDef() return project.defs.getEntityDef( getSelectedValue() );

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function canEdit():Bool {
		return super.canEdit() && getSelectedValue()>=0;
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

		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
		switch ge {
			case Entity(_) if( buttonId==0 ):
				editor.selectionTool.startUsing(m, buttonId);
				stopUsing(m);
				return;

			case PointField(_) if( buttonId==0 ):
				editor.selectionTool.startUsing(m, buttonId);
				stopUsing(m);
				return;

			case _:
		}

		if( buttonId!=2 )
			editor.selectionTool.clear();

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
						editor.selectionTool.select([ Entity(curLayerInstance, ei) ]);
						onEditAnything();
						stopUsing(m);
						editor.selectionTool.startUsing(m, button);
						editor.ge.emit( EntityInstanceAdded(ei) );
					}
				}

			case Remove:
				removeAnyEntityOrPointAt(m);
		}
	}


	function removeAnyEntityOrPointAt(m:MouseCoords) {
		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY, true);
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
					editor.selectionTool.select([ GenericLevelElement.Entity(li,ei) ]);
					return true;
				}
				else
					return false;

			case _:
		}

		return false;
	}


	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
		switch ge {
			case Entity(_): editor.selectionTool.onMouseMove(m);
			case PointField(_): editor.selectionTool.onMouseMove(m);
			case _:
		}
	}

	override function useAt(m:MouseCoords, isOnStop) {
		super.useAt(m,isOnStop);

		switch curMode {
			case null, PanView:
			case Add:

			case Remove:
				if( removeAnyEntityOrPointAt(m) )
					return true;
		}

		return false;
	}

	override function useOnRectangle(m:MouseCoords, left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(m, left, right, top, bottom);
		return false;
	}


	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.EntityPalette(this);
	}
}