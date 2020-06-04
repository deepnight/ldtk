package tool;

class EntityTool extends Tool<EntityDef> {
	public function new() {
		super();
	}

	override function selectValue(v:EntityDef) {
		super.selectValue(v);
	}

	override function getDefaultValue():EntityDef {
		return null; // TODO
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);
		client.ge.emit(LayerContentChanged);
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		client.ge.emit(LayerContentChanged);
	}



	override function updatePalette() {
		super.updatePalette();

		selectValue( getSelectedValue() );

		for(ed in project.entityDefs) {
			var e = new J("<li/>");
			jPalette.append(e);
			e.addClass("entity");
			if( ed==getSelectedValue() )
				e.addClass("active");

			e.append( JsTools.createEntity(ed, 1) );
			e.append(ed.name);

			e.click( function(_) {
				selectValue(ed);
				updatePalette();
			});
		}
	}
}