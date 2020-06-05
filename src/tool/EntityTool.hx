package tool;

class EntityTool extends Tool<Int> {
	var curEntityDef(get,never) : Null<EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.entityDefs.length>0 )
			selectValue( project.entityDefs[0].uid );
	}

	inline function get_curEntityDef() return project.getEntityDef(getSelectedValue());

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function getDefaultValue():Int{
		if( project.entityDefs.length>0 )
			return project.entityDefs[0].uid;
		else
			return -1;
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		if( curEntityDef==null )
			client.cursor.set(None);
		else
			client.cursor.set( Entity(curEntityDef, m.levelX, m.levelY) );
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		if( isAdding() ) {
			var ei = curLayer.createEntityInstance(curEntityDef);
			ei.x = m.levelX;
			ei.y = m.levelY;
			// ei.x = m.cx * curLayer.def.gridSize;
			// ei.y = m.cy * curLayer.def.gridSize;
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

			e.append( JsTools.createEntityPreview(ed, 0.75) );
			e.append(ed.name);

			e.click( function(_) {
				selectValue(ed.uid);
				updatePalette();
			});
		}
	}
}