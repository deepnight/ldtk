package ui.modal.dialog;

class RuleGroupRemap extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var srcGroup : data.DataTypes.AutoLayerRuleGroup;
	var groupJson : ldtk.Json.AutoLayerRuleGroupJson;

	var tileset : ui.Tileset;
	var idRemaps : Map<Int,Int> = new Map();
	var allTileIds : Array<Int> = [];
	var tileIdOffset = 0;

	public function new(ld:data.def.LayerDef, rg:data.DataTypes.AutoLayerRuleGroup, onConfirm:data.DataTypes.AutoLayerRuleGroup->Void) {
		super();

		loadTemplate("ruleGroupRemap.html");
		canBeClosedManually = false;

		this.ld = ld;
		this.srcGroup = rg;
		this.groupJson = ld.toJsonRuleGroup(rg);
		groupJson.name += " copy";

		var jName = jContent.find("input.name");
		jName.val(groupJson.name);
		jName.change( _->groupJson.name = jName.val() );

		// List used IntGrid IDs
		for(r in srcGroup.rules)
		for(cx in 0...r.size)
		for(cy in 0...r.size) {
			var v = M.iabs( r.get(cx,cy) );
			if( v!=0 && v!=Const.AUTO_LAYER_ANYTHING )
				idRemaps.set(v,v);
		}

		// Create ID remappers
		var jIdsList = jContent.find(".intGridIds");
		for(v in idRemaps.keyValueIterator())
			jIdsList.append( makeIdRemapper(v.key, v.value) );


		// Tile picker
		var td = project.defs.getTilesetDef(ld.tilesetDefUid);
		tileset = new ui.Tileset(jContent.find(".tileset"), td, PickSingle);
		var doneTileIds = new Map();
		allTileIds = [];
		for(r in srcGroup.rules)
		for(tid in r.tileIds)
			if( !doneTileIds.exists(tid) ) {
				doneTileIds.set(tid,true);
				allTileIds.push(tid);
			}
		allTileIds.sort( (a,b)->Reflect.compare(a,b) );
		tileset.onSelectAnything = ()->setTileOffset( tileset.getSelectedTileIds()[0] - allTileIds[0] );
		setTileOffset(0);

		// Confirm & remap!
		addConfirm(()->{
			// Create rulegroup copy
			var copy = ld.pasteRuleGroup( project, data.Clipboard.createTemp(CRuleGroup, groupJson) );

			// Offset all tileIds
			for(r in copy.rules)
			for(i in 0...r.tileIds.length)
				r.tileIds[i]+=tileIdOffset;

			// Remap IntGrid IDs
			for(r in copy.rules)
			for(cx in 0...r.size)
			for(cy in 0...r.size) {
				var v = r.get(cx,cy);
				if( idRemaps.exists(v) )
					r.set(cx,cy, idRemaps.get(v));
				else if( idRemaps.exists(-v) )
					r.set(cx,cy, -idRemaps.get(-v));
			}

			onConfirm(copy);
		});
		addCancel();
	}



	function setTileOffset(off:Int) {
		tileIdOffset = off;
		var offsetedIds = allTileIds.map( tid->tid+tileIdOffset );
		tileset.setHighlight(offsetedIds);
		tileset.focusAround(offsetedIds);
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