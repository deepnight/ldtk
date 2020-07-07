package tool;

class EntityTool extends Tool<Int> {
	var curEntityDef(get,never) : Null<led.def.EntityDef>;

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
			client.cursor.set(None);
		else if( isRunning() && curMode==Remove )
			client.cursor.set( Eraser(m.levelX,m.levelY) );
		else
			client.cursor.set( Entity(curEntityDef, getPlacementX(m), getPlacementY(m)) );
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		switch curMode {
			case null, PanView:
			case Add:
				var ei = curLayerInstance.createEntityInstance(curEntityDef);
				if( ei==null )
					N.error("Max per level reached!");
				else {
					ei.x = getPlacementX(m);
					ei.y = getPlacementY(m);
					client.setSelection( Entity(ei) );
					onEditAnything();
					curMode = Move;
				}

			case Remove:
				removeAnyEntityAt(m);

			case Move:
		}
	}

	function removeAnyEntityAt(m:MouseCoords) {
		var ge = getGenericLevelElementAt(m, curLayerInstance);
		switch ge {
			case Entity(instance):
				curLayerInstance.removeEntityInstance(instance);
				return true;

			case _:
		}

		return false;
	}

	function getPickedEntityInstance() : Null<led.inst.EntityInstance> {
		switch client.selection {
			case null, IntGrid(_), Tile(_):
				return null;

			case Entity(instance):
				return instance;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null, PanView:
			case Add:

			case Remove:
				if( removeAnyEntityAt(m) )
					return true;

			case Move:
				if( moveStarted ) {
					var ei = getPickedEntityInstance();
					var oldX = ei.x;
					var oldY = ei.y;
					ei.x = getPlacementX(m);
					ei.y = getPlacementY(m);
					client.setSelection( Entity(ei) );
					return oldX!=ei.x || oldY!=ei.y;
				}
		}

		return false;
	}

	override function onHistorySaving() {
		super.onHistorySaving();

		if( curMode==Move ) {
			var ei = getPickedEntityInstance();
			if( ei!=null )
				client.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
		}
	}


	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);
		return false;
		// client.ge.emit(LayerInstanceChanged);
	}


	override function createPalette() {
		var target = super.createPalette();

		var list = new J('<ul class="niceList"/>');
		list.appendTo(target);

		for(ed in project.defs.entities) {
			var e = new J("<li/>");
			list.append(e);
			e.addClass("entity");
			if( ed==curEntityDef )
				e.addClass("active");

			e.append( JsTools.createEntityPreview(ed, 32) );
			e.append(ed.name);

			e.click( function(_) {
				selectValue(ed.uid);
				list.find(".active").removeClass("active");
				e.addClass("active");
				updatePalette();
			});
		}

		return target;
	}

}