package ui.ts;

class TileToolPicker extends ui.Tileset {
	var tool : tool.lt.TileTool;

	public function new(jParent:js.jquery.JQuery, td:data.def.TilesetDef, tool:tool.lt.TileTool, saveUiState=false) {
		this.tool = tool;
		_internalSelectedIds = tool.getSelectedValue().ids;

		super(jParent, td, MultipleIndividuals, saveUiState);
	}

	override function getSelectedTileIds():Array<Int> {
		return tool!=null
			? tool.getSelectedValue().ids
			: super.getSelectedTileIds();
	}

	override function setSelectedTileIds(tileIds:Array<Int>) {
		tool.flipX = tool.flipY = false;
		tool.selectValue({ mode:tool.getMode(), ids:tileIds });
		super.setSelectedTileIds(tileIds);
	}

	override function renderSelection() {
		// no super call
		jSelection.empty();
		jSelection.append( createCursor(tool.getSelectedValue(), "selection") );
	}

	override function modifySelection(selIds:Array<Int>, add:Bool) {
		// Auto-pick saved selection
		if( selIds.length==1 && tilesetDef.hasSavedSelectionFor(selIds[0]) && !App.ME.isCtrlCmdDown() ) {
			// Check if the saved selection isn't already picked
			var saved = tilesetDef.getSavedSelectionFor( selIds[0] );
			if( !tool.selectedValuesIdentical(saved.ids) ) {
				// Recall saved selection entirely
				selIds = saved.ids.copy();
				tool.setMode( saved.mode );
			}
		}

		super.modifySelection(selIds, add);
	}


	public function navigate(dx:Int, dy:Int) {
		var tids = getSelectedTileIds();
		if( tids.length==0 )
			tids = [0];

		// Get min/max
		var minTid = 999999;
		var maxTid = -1;
		for(tid in tids) {
			minTid = M.imin(tid, minTid);
			maxTid = M.imax(tid, maxTid);
		}

		// Get current selection bounds
		var left = tilesetDef.getTileCx(minTid);
		var right = tilesetDef.getTileCx(maxTid);
		var top = tilesetDef.getTileCy(minTid);
		var bottom = tilesetDef.getTileCy(maxTid);
		var wid = ( right-left+1 );
		var hei = ( bottom-top+1 );

		// Try to pick a nearby saved selection
		var tcx = dx<0 ? left-1 : dx>0 ? right+1 : left;
		var tcy = dy<0 ? top-1 : dy>0 ? bottom+1 : top;
		var saved = tilesetDef.getSavedSelectionFor( tilesetDef.getTileId(tcx,tcy) );
		if( saved!=null ) {
			tool.setMode(saved.mode);
			setSelectedTileIds(saved.ids);
			focusOnSelection();
			Editor.ME.ge.emit(ToolValueSelected);
			return;
		}

		var wasOnSaved = tilesetDef.hasSavedSelectionFor(minTid);
		if( wasOnSaved )
			tids = [
				dx<0 ? tilesetDef.getTileId(left,top)
				: dx>0 ? tilesetDef.getTileId(right,top)
				: dy<0 ? tilesetDef.getTileId(left,top)
				: tilesetDef.getTileId(left,bottom)
			];


		// Loop on borders
		var looped = false;
		for(i in 0...tids.length) {
			if( dx!=0 ) {
				var cx = tilesetDef.getTileCx(tids[i]);
				if( cx+dx<0 ) {
					// Loop left
					dx = tilesetDef.cWid - tilesetDef.getTileCx(maxTid)-1;
					looped = true;
					break;
				}
				else if( cx+dx>=tilesetDef.cWid ) {
					// Loop right
					dx = -tilesetDef.cWid + ( tilesetDef.getTileCx(maxTid) - tilesetDef.getTileCx(minTid) ) + 1;
					looped = true;
					break;
				}
			}
			if( dy!=0 ) {
				var cy = tilesetDef.getTileCy(tids[i]);
				if( cy+dy<0 ) {
					// Loop top
					dy = tilesetDef.cHei - tilesetDef.getTileCy(maxTid)-1;
					looped = true;
					break;
				}
				else if( cy+dy>=tilesetDef.cHei ) {
					// Loop bottom
					dy = -tilesetDef.cHei + ( tilesetDef.getTileCy(maxTid) - tilesetDef.getTileCy(minTid) ) + 1;
					looped = true;
					break;
				}
			}
		}

		// Move selection
		var offset = dx + dy*tilesetDef.cWid;
		for(i in 0...tids.length)
			tids[i]+=offset;
		setSelectedTileIds(tids);
		focusOnSelection(looped);
		Editor.ME.ge.emit(ToolValueSelected);
	}

}