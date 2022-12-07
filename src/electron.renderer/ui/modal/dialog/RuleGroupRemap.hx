package ui.modal.dialog;

class RuleGroupRemap extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var srcGroup : data.DataTypes.AutoLayerRuleGroup;
	var groupJson : ldtk.Json.AutoLayerRuleGroupJson;

	var idRemaps : Map<Int,Int> = new Map();

	public function new(ld:data.def.LayerDef, rg:data.DataTypes.AutoLayerRuleGroup, onConfirm:data.DataTypes.AutoLayerRuleGroup->Void) {
		super();

		loadTemplate("ruleGroupRemap.html");

		this.ld = ld;
		this.srcGroup = rg;
		this.groupJson = ld.toJsonRuleGroup(rg);

		groupJson.name += " copy";

		// lastRule = copy.rules.length>0 ? copy.rules[0] : lastRule;
		// editor.ge.emit( LayerRuleGroupAdded(copy) );
		// for(r in copy.rules)
		// 	invalidateRuleAndOnesBelow(r);

		var jName = jContent.find("input.name");
		jName.val(groupJson.name);
		jName.change( _->groupJson.name = jName.val() );

		// List used IntGrid IDs
		var n = 0;
		for(r in srcGroup.rules)
		for(cx in 0...r.size)
		for(cy in 0...r.size) {
			var v = M.iabs( r.get(cx,cy) );
			if( v!=0 && v!=Const.AUTO_LAYER_ANYTHING ) {
				idRemaps.set(v,v);
				n++;
			}
		}
		if( n==0 )
			jContent.find(".intGridValues").hide();

		// Create ID remappers
		var jIdsList = jContent.find(".intGridIds");
		for(v in idRemaps.keyValueIterator())
			jIdsList.append( makeIdRemapper(v.key, v.value) );

		addConfirm(()->{
			// Create rulegroup copy
			var copy = ld.pasteRuleGroup( project, data.Clipboard.createTemp(CRuleGroup, groupJson) );

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