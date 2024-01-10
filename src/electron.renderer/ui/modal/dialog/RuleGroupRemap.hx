package ui.modal.dialog;

class RuleGroupRemap extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var td : data.def.TilesetDef;
	var srcGroup : data.def.AutoLayerRuleGroupDef;
	var copyJson : ldtk.Json.AutoLayerRuleGroupJson;

	var tileset : ui.Tileset;
	var idRemaps : Map<Int,Int> = new Map();
	var allTileIds : Array<Int> = [];
	var tileOffsetX = 0;
	var tileOffsetY = 0;

	public function new(ld:data.def.LayerDef, rg:data.def.AutoLayerRuleGroupDef, onConfirm:data.def.AutoLayerRuleGroupDef->Void) {
		super();

		loadTemplate("ruleGroupRemap.html", { name:rg.name });
		canBeClosedManually = false;

		this.ld = ld;
		this.srcGroup = rg;
		this.copyJson = rg.toJson(ld);
		copyJson.name += " copy";

		// List used IntGrid IDs
		for(r in srcGroup.rules)
		for(cx in 0...r.size)
		for(cy in 0...r.size) {
			var v = M.iabs( r.getPattern(cx,cy) );
			if( v!=0 && v!=Const.AUTO_LAYER_ANYTHING )
				idRemaps.set(v,v);
		}

		// Create ID remappers
		var jIdsList = jContent.find(".intGridIds");
		for(v in idRemaps.keyValueIterator())
			jIdsList.append( makeIdRemapper(v.key, v.value) );


		// Tile picker
		td = project.defs.getTilesetDef(ld.tilesetDefUid);
		tileset = new ui.Tileset(jContent.find(".tileset"), td, OneTile);
		var doneTileIds = new Map();
		allTileIds = [];
		for(r in srcGroup.rules)
		for(rectIds in r.tileRectsIds)
		for(tid in rectIds)
			if( !doneTileIds.exists(tid) ) {
				doneTileIds.set(tid,true);
				allTileIds.push(tid);
			}
		allTileIds.sort( (a,b)->Reflect.compare(a,b) );
		tileset.onSelectAnything = ()->{
			var tid = tileset.getSelectedTileIds()[0];
			var fcx = td.getTileCx( allTileIds[0] );
			var fcy = td.getTileCy( allTileIds[0] );
			var tcx = td.getTileCx(tid);
			var tcy = td.getTileCy(tid);
			setTileOffset(tcx-fcx, tcy-fcy);
			// setTileOffset( tileset.getSelectedTileIds()[0] - allTileIds[0] );
		}
		setTileOffset(0,0,true);
		tileset.fitView();

		// Confirm & remap!
		addButton(L.t._("Confirm"), ()->{
			new InputDialog(
				L.t._("Name this new group"),
				copyJson.name,
				(s:String)->return s.length==0 ? "Please enter a valid name" : null,
				(s:String)->return s,
				(s:String)->{
					// Create rulegroup copy
					var copyGroup = ld.pasteRuleGroup( project, data.Clipboard.createTemp(CRuleGroup, copyJson), rg );
					copyGroup.name = s;

					// Offset all tileIds
					for(r in copyGroup.rules)
					for(rectIds in r.tileRectsIds)
					for(i in 0...rectIds.length)
						rectIds[i] += tileOffsetX + tileOffsetY*td.cWid;

					// Remap IntGrid IDs
					for(r in copyGroup.rules) {
						for(cx in 0...r.size)
						for(cy in 0...r.size) {
							var v = r.getPattern(cx,cy);
							if( idRemaps.exists(v) )
								r.setPattern(cx,cy, idRemaps.get(v));
							else if( idRemaps.exists(-v) )
								r.setPattern(cx,cy, -idRemaps.get(-v));
						}
						r.updateUsedValues();
					}

					// Out-of-bounds value
					for(r in copyGroup.rules)
						if( r.outOfBoundsValue!=null && idRemaps.exists(r.outOfBoundsValue) )
							r.outOfBoundsValue = idRemaps.get(r.outOfBoundsValue);

					onConfirm(copyGroup);
					close();
				}
			);


		});
		addCancel();
	}


	function getCenterOfGroup(tileIds:Array<Int>) {
		var sumX = 0.;
		var sumY = 0.;
		for(tid in tileIds) {
			sumX += td.getTileSourceX(tid);
			sumY += td.getTileSourceY(tid);
		}
		return {
			x: M.round( sumX / tileIds.length ),
			y: M.round( sumY / tileIds.length ),
		}
	}

	function lock() {
		jWrapper.find("button.confirm").prop("disabled",true);
	}
	function unlock() {
		jWrapper.find("button.confirm").prop("disabled",false);
	}


	function setTileOffset(ox:Int, oy:Int, scrollTo=false) {
		tileOffsetX = ox;
		tileOffsetY = oy;

		var valid = true;
		var offsetedIds = [];
		for(tid in allTileIds) {
			var tcx = td.getTileCx(tid) + tileOffsetX;
			var tcy = td.getTileCy(tid) + tileOffsetY;
			if( tcx>=0 && tcx<td.cWid && tcy>=0 && tcy<td.cHei )
				offsetedIds.push(tid+tileOffsetX + tileOffsetY*td.cWid);
			else
				valid = false;
		}

		if( valid )
			unlock();
		else
			lock();

		tileset.clearCursor();
		tileset.renderAtlas();

		// Render original group
		if( tileOffsetX!=0 || tileOffsetY!=0 )
			tileset.renderHighlightedTiles(allTileIds, "#080");

		// Render offseted group
		tileset.renderHighlightedTiles(offsetedIds, valid?dn.Col.inlineHex("#0f0"):dn.Col.inlineHex("#f00"));

		// Render arrow
		if( tileOffsetX!=0 || tileOffsetY!=0 ) {
			var idx = 0;
			var offX = Std.int(td.tileGridSize*0.5);
			var offY = offX;
			for(idx in 0...allTileIds.length) {
				if( idx>=offsetedIds.length )
					break;
				tileset.renderArrow(
					td.getTileSourceX(allTileIds[idx])+offX, td.getTileSourceY(allTileIds[idx])+offY,
					td.getTileSourceX(offsetedIds[idx])+offX, td.getTileSourceY(offsetedIds[idx])+offY,
					valid ? dn.Col.inlineHex("#fff") : dn.Col.inlineHex("#f00")
				);
			}
			// var from = getCenterOfGroup(allTileIds);
			// var to = getCenterOfGroup(offsetedIds);
			// tileset.renderArrow(from.x, from.y, to.x, to.y, valid?dn.Col.inlineHex("#fff"):dn.Col.inlineHex("#f00"));
		}

		// Focus
		if( scrollTo )
			tileset.focusAround(offsetedIds, true);
	}


	function makeIntGridId(id:Int, ?className:String, ?nameOverride:String) {
		var jId = new J('<div></div>');
		if( className!=null )
			jId.addClass(className);


		if( nameOverride!=null )
			jId.append(nameOverride);
		else if( ld.getIntGridValueDisplayName(id)!=null )
			jId.append(ld.getIntGridValueDisplayName(id));
		else
			jId.append('#$id');

		jId.css({ backgroundColor: ld.getIntGridValueColor(id).toHex() });
		return jId;
	}


	function makeIdRemapper(oldId:Int, newId:Int) : js.jquery.JQuery {
		var jMapper = new J("<li/>");

		var jOld = makeIntGridId(oldId, "oldId");
		jMapper.append(jOld);

		jMapper.append('<div class="icon right"/>');

		var jNew = makeIntGridId(newId, newId==oldId?"newId unchanged":"newId", newId==oldId?"No change":null);
		jMapper.append(jNew);
		jNew.click( _->{
			new ui.modal.dialog.IntGridValuePicker(ld, newId, id->{
				idRemaps.set(oldId, id);
				jMapper.replaceWith( makeIdRemapper(oldId, id) );
			});
		});

		return jMapper;
	}
}