package tool;

class EntityTool extends Tool<Int> {
	var curEntityDef(get,never) : Null<EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.entityDefs.length>0 )
			selectValue( project.entityDefs[0].uid );
	}

	function snapToGrid() return !client.isCtrlDown() || cd.has("requireCtrlRelease");

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
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayerContent.def.gridSize )
			: m.levelX;
	}

	function getPlacementY(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayerContent.def.gridSize )
			: m.levelY;
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( curEntityDef==null )
			client.cursor.set(None);
		else if( isRunning() && curMode==Remove )
			client.cursor.set( Eraser(m.levelX,m.levelY) );
		else
			client.cursor.set( Entity(curEntityDef, getPlacementX(m), getPlacementY(m)) );
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		cd.unset("requireCtrlRelease");

		super.startUsing(m, buttonId);

		switch curMode {
			case null:
			case Add:
				var ei = curLayerContent.createEntityInstance(curEntityDef);
				ei.x = getPlacementX(m);
				ei.y = getPlacementY(m);
				client.ge.emit(LayerContentChanged);

			case Remove:
				removeAnyEntityAt(m);

			case Move:
				if( client.isCtrlDown() )
					cd.setS("requireCtrlRelease", Const.INFINITE);
		}
	}

	function removeAnyEntityAt(m:MouseCoords) {
		var ge = getGenericLevelElementAt(m, curLayerContent);
		switch ge {
			case Entity(instance):
				curLayerContent.removeEntityInstance(instance);
				client.ge.emit(LayerContentChanged);
				return true;

			case _:
		}

		return false;
	}

	function getPickedEntityInstance() : Null<EntityInstance> {
		switch pickedElement {
			case null, IntGrid(_):
				return null;

			case Entity(instance):
				return instance;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null:
			case Add:

			case Remove:
				removeAnyEntityAt(m);

			case Move:
				var ei = getPickedEntityInstance();
				ei.x = getPlacementX(m);
				ei.y = getPlacementY(m);
				client.ge.emit(LayerContentChanged);
		}
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

	override function update() {
		super.update();
		if( !client.isCtrlDown() && cd.has("requireCtrlRelease") )
			cd.unset("requireCtrlRelease");
	}
}