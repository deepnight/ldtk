package data.def;

class AutoLayerRuleGroupDef {
	public var uid : Int;
	public var name : String;

	public var color: Null<dn.Col>;
	public var icon: Null<ldtk.Json.TilesetRect>;
	public var active = true;
	public var collapsed = false;
	public var rules : Array<data.def.AutoLayerRuleDef> = [];
	public var isOptional = false;
	public var usesWizard = false;
	public var requiredBiomeValues : Array<String> = [];
	public var biomeRequirementMode = 0;

	public function new(uid:Int, name:String) {
		this.uid = uid;
		this.name = name;
	}

	@:keep
	public function toString() {
		return name;
	}

	public static function fromJson(jsonVersion:String, json:ldtk.Json.AutoLayerRuleGroupJson) : AutoLayerRuleGroupDef {
		var rg = new AutoLayerRuleGroupDef(
			JsonTools.readInt(json.uid,-1),
			JsonTools.readString(json.name, "default")
		);
		rg.color = JsonTools.readColor(json.color, true);
		rg.active = JsonTools.readBool( json.active, true );
		rg.isOptional = JsonTools.readBool( json.isOptional, false );
		rg.icon = JsonTools.readTileRect( json.icon, true );
		rg.rules = JsonTools.readArray( json.rules ).map( function(ruleJson) {
			return AutoLayerRuleDef.fromJson(jsonVersion, ruleJson);
		});
		rg.collapsed = true;
		rg.usesWizard = JsonTools.readBool( json.usesWizard, false );
		rg.requiredBiomeValues = json.requiredBiomeValues!=null ? json.requiredBiomeValues.copy() : [];
		rg.biomeRequirementMode = JsonTools.readInt( json.biomeRequirementMode, 0 );
		return rg;
	}



	public function toJson(ld:LayerDef) : ldtk.Json.AutoLayerRuleGroupJson {
		return {
			uid: uid,
			name: name,
			color: color!=null ? color.toHex() : null,
			icon: JsonTools.writeTileRect(icon),
			active: active,
			isOptional: isOptional,
			rules: rules.map( function(r) return r.toJson(ld) ),
			usesWizard: usesWizard,
			requiredBiomeValues: requiredBiomeValues.copy(),
			biomeRequirementMode: biomeRequirementMode,
		}
	}

}