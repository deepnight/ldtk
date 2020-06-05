package tool;

class EntityTool extends Tool<Int> {
	var curEntityDef(get,never) : Null<EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.entityDefs.length>0 )
			selectValue( project.entityDefs[0].uid );
	}

	function snapToGrid() return !client.isCtrlDown();

	inline function get_curEntityDef() return project.getEntityDef(getSelectedValue());

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function canBeUsed():Bool {
		return super.canBeUsed() && getSelectedValue()>=0;
	}

	override function getDefaultValue():Int{
		if( project.entityDefs.length>0 )
			return project.entityDefs[0].uid;
		else
			return -1;
	}

	function getPlacementX(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayer.def.gridSize )
			// ? M.round( ( m.cx + curEntityDef.pivotX ) * curLayer.def.gridSize ) + ( curEntityDef.pivotX==1 ? -1 : 0 )
			: m.levelX;
	}

	function getPlacementY(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayer.def.gridSize )
			// ? M.round( ( m.cy + curEntityDef.pivotY ) * curLayer.def.gridSize ) + ( curEntityDef.pivotY==1 ? -1 : 0 )
			: m.levelY;
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		if( curEntityDef==null )
			client.cursor.set(None);
		else if( snapToGrid() )
			client.cursor.set( Entity(curEntityDef, getPlacementX(m), getPlacementY(m)) );
		else
			client.cursor.set( Entity(curEntityDef, m.levelX, m.levelY) );
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		if( isAdding() ) {
			var ei = curLayer.createEntityInstance(curEntityDef);
			ei.x = getPlacementX(m);
			ei.y = getPlacementY(m);
			N.debug( ei.getCy(curLayer.def) );
			client.ge.emit(LayerContentChanged);
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		client.ge.emit(LayerContentChanged);
	}



	override function updatePalette() {
		super.updatePalette();

		for(ed in project.entityDefs) {
			var e = new J("<li/>");
			jPalette.append(e);
			e.addClass("entity");
			if( ed==curEntityDef )
				e.addClass("active");

			e.append( JsTools.createEntityPreview(ed, 32) );
			e.append(ed.name);

			e.click( function(_) {
				selectValue(ed.uid);
				updatePalette();
			});
		}
	}
}