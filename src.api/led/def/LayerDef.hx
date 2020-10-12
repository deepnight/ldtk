package led.def;

import led.LedTypes;

class LayerDef {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var identifier(default,set) : String;
	public var gridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var displayOpacity : Float = 1.0;

	// IntGrid
	var intGridValues : Array<IntGridValueDef> = [];

	// IntGrid/AutoLayers
	public var autoTilesetDefUid : Null<Int>;
	public var autoSourceLayerDefUid : Null<Int>;
	public var autoRuleGroups : Array<AutoLayerRuleGroup> = [];

	// Tiles
	public var tilesetDefUid : Null<Int>;
	public var tilePivotX(default,set) : Float = 0;
	public var tilePivotY(default,set) : Float = 0;

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		type = t;
		#if editor
		identifier = Lang.getLayerType(type)+uid;
		#else
		identifier = type+uid;
		#end
		addIntGridValue(0x0);
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id,true);
		return identifier = id==null ? identifier : id;
	}

	@:keep public function toString() {
		return '$identifier($type, ${gridSize}px)';
	}

	public static function fromJson(jsonVersion:String, json:led.Json.LayerDefJson) {
		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(LayerType, json.type, false));
		o.identifier = JsonTools.readString(json.identifier, "Layer"+o.uid);
		o.gridSize = JsonTools.readInt(json.gridSize, Project.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);

		o.intGridValues = [];
		for( v in JsonTools.readArray(json.intGridValues) )
			o.intGridValues.push({
				identifier: v.identifier,
				color: JsonTools.readColor(v.color),
			});

		o.autoTilesetDefUid = JsonTools.readNullableInt(json.autoTilesetDefUid);
		o.autoSourceLayerDefUid = JsonTools.readNullableInt(json.autoSourceLayerDefUid);

		// Read auto-layer rules
		if( json.autoRuleGroups!=null ) {
			for( ruleGroupJson in JsonTools.readArray(json.autoRuleGroups) ) {
				var rg = o.createRuleGroup(
					JsonTools.readInt(ruleGroupJson.uid,-1),
					JsonTools.readString(ruleGroupJson.name, "default")
				);
				rg.active = JsonTools.readBool( ruleGroupJson.active, true );
				rg.collapsed = JsonTools.readBool( ruleGroupJson.collapsed, false );
				rg.rules = JsonTools.readArray( ruleGroupJson.rules ).map( function(ruleJson) {
					return AutoLayerRuleDef.fromJson(jsonVersion, ruleJson);
				});
			}
		}

		o.tilesetDefUid = JsonTools.readNullableInt(json.tilesetDefUid);
		o.tilePivotX = JsonTools.readFloat(json.tilePivotX, 0);
		o.tilePivotY = JsonTools.readFloat(json.tilePivotY, 0);

		return o;
	}

	public function toJson() : led.Json.LayerDefJson {
		return {
			__type: Std.string(type),

			identifier: identifier,
			type: JsonTools.writeEnum(type, false),
			uid: uid,
			gridSize: gridSize,
			displayOpacity: JsonTools.writeFloat(displayOpacity),

			intGridValues: intGridValues.map( function(iv) return { identifier:iv.identifier, color:JsonTools.writeColor(iv.color) }),

			autoTilesetDefUid: autoTilesetDefUid,
			autoRuleGroups: autoRuleGroups.map( function(rg) return {
				uid: rg.uid,
				name: rg.name,
				active: rg.active,
				collapsed: rg.collapsed,
				rules: rg.rules.map( function(r) return r.toJson() ),
			}),
			autoSourceLayerDefUid: autoSourceLayerDefUid,

			tilesetDefUid: tilesetDefUid,
			tilePivotX: tilePivotX,
			tilePivotY: tilePivotY,
		}
	}


	public function addIntGridValue(col:UInt, ?id:String) {
		if( !isIntGridValueIdentifierValid(id) )
			throw "Invalid intGrid value identifier "+id;

		intGridValues.push({
			color: col,
			identifier: id,
		});
	}

	public inline function getIntGridValueDef(idx:Int) : Null<IntGridValueDef> {
		return intGridValues[idx];
	}

	public inline function getIntGridValueDisplayName(idx:Int) : Null<String> {
		var vd = getIntGridValueDef(idx);
		return vd==null ? null : vd.identifier==null ? '#$idx' : '#$idx (${vd.identifier})';
	}

	public inline function getIntGridValueColor(idx:Int) : Null<UInt> {
		var vd = getIntGridValueDef(idx);
		return vd==null ? null : vd.color;
	}

	public inline function getAllIntGridValues() return intGridValues;
	public inline function countIntGridValues() return intGridValues.length;

	public function isIntGridValueIdentifierValid(id:Null<String>) {
		if( id==null || id=="" )
			return true;

		if( !Project.isValidIdentifier(id) )
			return false;

		for(v in intGridValues)
			if( v.identifier==id )
				return false;

		return true;
	}



	public function isUsingTileset(td:TilesetDef) {
		return tilesetDefUid==td.uid || autoTilesetDefUid==td.uid;
	}


	inline function set_tilePivotX(v) return tilePivotX = dn.M.fclamp(v, 0, 1);
	inline function set_tilePivotY(v) return tilePivotY = dn.M.fclamp(v, 0, 1);


	public inline function isAutoLayer() {
		return type==IntGrid && autoTilesetDefUid!=null || type==AutoLayer;
	}


	public function hasRule(ruleUid:Int) : Bool {
		for(rg in autoRuleGroups)
		for(r in rg.rules)
			if( r.uid==ruleUid )
				return true;
		return false;
	}

	public function getRule(uid:Int) : Null<AutoLayerRuleDef> {
		for( rg in autoRuleGroups )
		for( r in rg.rules )
			if( r.uid==uid )
				return r;
		return null;
	}

	public function removeRuleGroup(rg:AutoLayerRuleGroup) {
		for( g in autoRuleGroups )
			if( g.uid==rg.uid ) {
				autoRuleGroups.remove(g);
				return true;
			}
		return false;
	}

	public function createRuleGroup(uid:Int, name:String, ?index:Int) {
		var rg : AutoLayerRuleGroup = {
			uid: uid,
			name: name,
			active: true,
			collapsed: false,
			rules: [],
		}
		if( index!=null )
			autoRuleGroups.insert(index, rg);
		else
			autoRuleGroups.push(rg);
		return rg;
	}

	public inline function iterateActiveRulesInDisplayOrder( cbEachRule:(r:AutoLayerRuleDef)->Void ) {
		var ruleGroupIdx = autoRuleGroups.length-1;
		while( ruleGroupIdx>=0 ) {
			// Groups
			if( autoRuleGroups[ruleGroupIdx].active ) {
				var rg = autoRuleGroups[ruleGroupIdx];
				var ruleIdx = rg.rules.length-1;
				while( ruleIdx>=0 ) {
					// Rules
					if( rg.rules[ruleIdx].active )
						cbEachRule( rg.rules[ruleIdx] );

					ruleIdx--;
				}
			}
			ruleGroupIdx--;
		}
	}

	public function tidy(p:led.Project) {
		// Lost auto-layer tileset
		if( autoTilesetDefUid!=null && p.defs.getTilesetDef(autoTilesetDefUid)==null ) {
			autoTilesetDefUid = null;
			for(rg in autoRuleGroups)
			for(r in rg.rules)
				r.tileIds = [];
		}
	}
}