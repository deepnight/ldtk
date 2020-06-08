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


	override function onPick() {
		super.onPick();

		switch pickedElement {
			case null:
			case IntGrid(lc, cx, cy):
			case Entity(instance):
				showInstanceEditor(instance);
		}
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		switch curMode {
			case null, PanView:
			case Add:
				var ei = curLayerContent.createEntityInstance(curEntityDef);
				ei.x = getPlacementX(m);
				ei.y = getPlacementY(m);
				client.ge.emit(LayerContentChanged);
				showInstanceEditor(ei);

			case Remove:
				removeAnyEntityAt(m);

			case Move:
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
			case null, PanView:
			case Add:

			case Remove:
				removeAnyEntityAt(m);

			case Move:
				if( moveStarted ) {
					var ei = getPickedEntityInstance();
					ei.x = getPlacementX(m);
					ei.y = getPlacementY(m);
					client.ge.emit(LayerContentChanged);
				}
		}
	}

	function hideInstanceEditor() {
		var panel = client.jSubPanel;
		panel.empty();
	}

	function showInstanceEditor(ei:EntityInstance) {
		var panel = client.jSubPanel;
		panel.empty();
		panel.append("<p>"+ei.def.name+"</p>");

		var form = new J('<ul class="form"/>');
		form.appendTo(panel);
		for(fv in ei.fieldInstances) {
			var li = new J("<li/>");
			li.appendTo(form);
			li.append('<label>${fv.def.name}</label>');

			switch fv.def.type {
				case F_Int:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","text");
					input.attr("placeholder", fv.def.getDefault()==null ? "(null)" : fv.def.getDefault());
					if( !fv.isUsingDefault() )
						input.val( Std.string(fv.getInt()) );
					input.change( function(ev) {
						fv.parseValue( input.val() );
						showInstanceEditor(ei);
					});

				case F_Float:
				case F_String:
				case F_Bool:
			}
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
}