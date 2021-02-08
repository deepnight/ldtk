package tool.lt;

class EntityTool extends tool.LayerTool<Int> {
	public var curEntityDef(get,never) : Null<data.def.EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.defs.entities.length>0 )
			selectValue( project.defs.entities[0].uid );
	}

	override function onBeforeToolActivation() {
		super.onBeforeToolActivation();

		if( curEntityDef==null )
			selectValue( getDefaultValue() );
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

	function getPlacementX(m:Coords) {
		return snapToGrid()
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayerInstance.def.gridSize )
			: m.levelX;
	}

	function getPlacementY(m:Coords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayerInstance.def.gridSize )
			: m.levelY;
	}

	override function updateCursor(m:Coords) {
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


	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);

		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
		switch ge {
			case Entity(_) if( ev.button==0 ):
				editor.selectionTool.select([ge]);
				editor.selectionTool.startUsing(ev,m);
				stopUsing(m);
				return;

			case PointField(_) if( ev.button==0 ):
				editor.selectionTool.select([ge]);
				editor.selectionTool.startUsing(ev,m);
				stopUsing(m);
				return;

			case _:
		}

		if( ev.button!=2 )
			editor.selectionTool.clear();

		switch curMode {
			case null:
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
						editor.selectionTool.startUsing(ev, m);
						editor.ge.emit( EntityInstanceAdded(ei) );
					}
				}

			case Remove:
				removeAnyEntityOrPointAt(m);
		}
	}


	function removeAnyEntityOrPointAt(m:Coords) {
		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY, true);
		switch ge {
			case Entity(curLayerInstance, instance):
				curLayerInstance.removeEntityInstance(instance);
				editor.ge.emit( EntityInstanceRemoved(instance) );
				editor.levelRender.bleepEntity(instance);
				return true;

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				if( pt!=null && pt.cx==m.cx && pt.cy==m.cy ) {
					if( fi.def.isArray )
						fi.removeArrayValue(arrayIdx);
					else
						fi.parseValue(arrayIdx, null);
					editor.ge.emit( EntityFieldInstanceChanged(ei) );
					editor.selectionTool.select([ GenericLevelElement.Entity(li,ei) ]);
					editor.levelRender.bleepPoint(
						(pt.cx+0.5) * li.def.gridSize,
						(pt.cy+0.5) * li.def.gridSize,
						ei.getSmartColor(true)
					);
					return true;
				}
				else
					return false;

			case _:
		}

		return false;
	}


	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);

		var ge = editor.getGenericLevelElementAt(m.levelX, m.levelY);
		switch ge {
			case Entity(_): editor.selectionTool.onMouseMove(ev,m);
			case PointField(_): editor.selectionTool.onMouseMove(ev,m);
			case _:
		}
	}

	override function useAt(m:Coords, isOnStop) {
		super.useAt(m,isOnStop);

		switch curMode {
			case null:
			case Add:

			case Remove:
				if( removeAnyEntityOrPointAt(m) )
					return true;
		}

		return false;
	}

	override function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(m, left, right, top, bottom);
		return false;
	}


	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.EntityPalette(this);
	}
}