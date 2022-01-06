package ui.ts;

class TileToolPicker extends ui.Tileset {
	var tool : tool.lt.TileTool;

	public function new(jParent:js.jquery.JQuery, td:data.def.TilesetDef, tool:tool.lt.TileTool) {
		this.tool = tool;
		_internalSelectedIds = tool.getSelectedValue().ids;

		super(jParent, td, Free);
	}

	override function getSelectedTileIds():Array<Int> {
		return tool!=null
			? tool.getSelectedValue().ids
			: super.getSelectedTileIds();
	}

	override function setSelectedTileIds(tileIds:Array<Int>) {
		super.setSelectedTileIds(tileIds);
		tool.flipX = tool.flipY = false;
		tool.selectValue({ mode:tool.getMode(), ids:tileIds });
	}

	override function renderSelection() {
		// no super call
		jSelection.empty();
		jSelection.append( createCursor(tool.getSelectedValue(), "selection") );
	}

	override function modifySelection(selIds:Array<Int>, add:Bool) {
		// Auto-pick saved selection
		if( selIds.length==1 && tilesetDef.hasSavedSelectionFor(selIds[0]) && !App.ME.isCtrlDown() ) {
			// Check if the saved selection isn't already picked
			var saved = tilesetDef.getSavedSelectionFor( selIds[0] );
			if( !tool.selectedValueHasAny(saved.ids) ) {
				// Recall saved selection
				selIds = saved.ids.copy();
				tool.setMode( saved.mode );
			}
		}

		super.modifySelection(selIds, add);
	}
}