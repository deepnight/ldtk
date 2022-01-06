package data.def;

import data.DataTypes;

class LayerDef {
	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var type : ldtk.Json.LayerType;
	public var identifier(default,set) : String;
	public var gridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var scaledGridSize(get,never) : Float; inline function get_scaledGridSize() return gridSize*getScale();
	public var displayOpacity : Float = 1.0;
	public var fadeInactive = false;
	public var hideInList = false;
	public var pxOffsetX : Int = 0;
	public var pxOffsetY : Int = 0;
	public var parallaxFactorX : Float = 0.;
	public var parallaxFactorY : Float = 0.;
	public var parallaxScaling : Bool = true;

	// Entities
	public var requiredTags : Tags;
	public var excludedTags : Tags;

	// IntGrid
	@:allow(importer)
	var intGridValues : Array<IntGridValueDef> = [];

	// IntGrid/AutoLayers
	public var autoTilesetDefUid : Null<Int>;
	public var autoSourceLayerDefUid : Null<Int>;
	public var autoRuleGroups : Array<AutoLayerRuleGroup> = [];

	// Tiles
	public var tilesetDefUid : Null<Int>;
	public var tilePivotX(default,set) : Float = 0;
	public var tilePivotY(default,set) : Float = 0;

	public function new(uid:Int, t:ldtk.Json.LayerType) {
		this.uid = uid;
		type = t;
		#if editor
		identifier = Std.string( Lang.getLayerType(type) ) + uid;
		#else
		identifier = type+uid;
		#end
		addIntGridValue(0x0);
		requiredTags = new Tags();
		excludedTags = new Tags();
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id,true);
		return identifier = id==null ? identifier : id;
	}

	@:keep public function toString() {
		return 'LayerDef.$identifier($type,${gridSize}px)';
	}

	public static function fromJson(p:Project, jsonVersion:String, json:ldtk.Json.LayerDefJson) {
		if( (cast json).tilesetDefId!=null )
			json.tilesetDefUid = (cast json).tilesetDefId;

		if( (cast json).parallaxFactor!=null )
			json.parallaxFactorX = json.parallaxFactorY = (cast json).parallaxFactor;

		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(ldtk.Json.LayerType, json.type, false));
		o.identifier = JsonTools.readString(json.identifier, "Layer"+o.uid);
		o.gridSize = JsonTools.readInt(json.gridSize, Project.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);
		o.fadeInactive = JsonTools.readBool(json.fadeInactive, false);
		o.hideInList = JsonTools.readBool(json.hideInList, false);
		o.pxOffsetX = JsonTools.readInt(json.pxOffsetX, 0);
		o.pxOffsetY = JsonTools.readInt(json.pxOffsetY, 0);
		o.parallaxFactorX = JsonTools.readFloat(json.parallaxFactorX, 0);
		o.parallaxFactorY = JsonTools.readFloat(json.parallaxFactorY, 0);
		o.parallaxScaling = JsonTools.readBool(json.parallaxScaling, true);

		o.requiredTags = Tags.fromJson(json.requiredTags);
		o.excludedTags = Tags.fromJson(json.excludedTags);

		o.intGridValues = [];
		var all : Array<IntGridValueDef> = JsonTools.readArray(json.intGridValues);
		for( v in all ) {
			o.intGridValues.push({
				value: v.value,
				identifier: v.identifier,
				color: JsonTools.readColor(v.color),
			});
		}

		o.autoTilesetDefUid = JsonTools.readNullableInt(json.autoTilesetDefUid);
		o.autoSourceLayerDefUid = JsonTools.readNullableInt(json.autoSourceLayerDefUid);

		// Read auto-layer rules
		if( json.autoRuleGroups!=null ) {
			for( ruleGroupJson in json.autoRuleGroups )
				o.parseJsonRuleGroup(jsonVersion, ruleGroupJson);
		}

		o.tilesetDefUid = JsonTools.readNullableInt(json.tilesetDefUid);
		o.tilePivotX = JsonTools.readFloat(json.tilePivotX, 0);
		o.tilePivotY = JsonTools.readFloat(json.tilePivotY, 0);

		return o;
	}

	public function toJson() : ldtk.Json.LayerDefJson {
		return {
			__type: Std.string(type),

			identifier: identifier,
			type: JsonTools.writeEnum(type, false),
			uid: uid,
			gridSize: gridSize,
			displayOpacity: JsonTools.writeFloat(displayOpacity),
			fadeInactive: fadeInactive,
			hideInList: hideInList,
			pxOffsetX: pxOffsetX,
			pxOffsetY: pxOffsetY,
			parallaxFactorX: parallaxFactorX,
			parallaxFactorY: parallaxFactorY,
			parallaxScaling: parallaxScaling,
			requiredTags: requiredTags.toJson(),
			excludedTags: excludedTags.toJson(),

			intGridValues: intGridValues.map( function(iv) return {
				value: iv.value,
				identifier: iv.identifier,
				color: JsonTools.writeColor(iv.color),
			}),

			autoTilesetDefUid: autoTilesetDefUid,
			autoRuleGroups: isAutoLayer() ? autoRuleGroups.map( function(rg) return toJsonRuleGroup(rg)) : [],
			autoSourceLayerDefUid: autoSourceLayerDefUid,

			tilesetDefUid: tilesetDefUid,
			tilePivotX: tilePivotX,
			tilePivotY: tilePivotY,
		}
	}

	public function toJsonRuleGroup(rg:AutoLayerRuleGroup) : ldtk.Json.AutoLayerRuleGroupJson {
		return {
			uid: rg.uid,
			name: rg.name,
			active: rg.active,
			collapsed: rg.collapsed,
			isOptional: rg.isOptional,
			rules: rg.rules.map( function(r) return r.toJson() ),
		}
	}

	public function parseJsonRuleGroup(jsonVersion:String, ruleGroupJson:ldtk.Json.AutoLayerRuleGroupJson) : AutoLayerRuleGroup {
		var rg = createRuleGroup(
			JsonTools.readInt(ruleGroupJson.uid,-1),
			JsonTools.readString(ruleGroupJson.name, "default")
		);
		rg.active = JsonTools.readBool( ruleGroupJson.active, true );
		rg.collapsed = JsonTools.readBool( ruleGroupJson.collapsed, false );
		rg.isOptional = JsonTools.readBool( ruleGroupJson.isOptional, false );
		rg.rules = JsonTools.readArray( ruleGroupJson.rules ).map( function(ruleJson) {
			return AutoLayerRuleDef.fromJson(jsonVersion, ruleJson);
		});
		return rg;
	}

	public inline function getScale() : Float {
		return !parallaxScaling || parallaxFactorX==0 ? 1 : M.fmax( 0.01, 1-parallaxFactorX );
	}


	public function sortIntGridValueDef(from:Int, to:Int) : Null<IntGridValueDef> {
		if( type!=IntGrid )
			return null;

		if( from<0 || from>=intGridValues.length || from==to )
			return null;

		if( to<0 || to>=intGridValues.length )
			return null;

		var moved = intGridValues.splice(from,1)[0];
		intGridValues.insert(to, moved);

		return moved;
	}

	function getNextIntGridValue() {
		if( intGridValues.length==0 )
			return 1;
		var max = 1;
		for(v in intGridValues)
			max = M.imax(v.value, max);
		return max+1;
	}

	public function addIntGridValue(col:UInt, ?id:String) {
		if( !isIntGridValueIdentifierValid(id) )
			throw "Invalid intGrid value identifier "+id;

		intGridValues.push({
			value: getNextIntGridValue(),
			color: col,
			identifier: id,
		});
	}

	public inline function hasIntGridValue(v:Int) {
		return getIntGridValueDef(v)!=null;
	}

	public inline function getIntGridValueDef(value:Int) : Null<IntGridValueDef> {
		var out : Null<IntGridValueDef> = null;
		for(v in intGridValues)
			if( v.value==value ) {
				out = v;
				break;
			}
		return out;
	}

	public function getIntGridIndexFromIdentifier(id:String) : Int {
		var idx = 1;
		for( v in intGridValues )
			if( v.identifier==id )
				return idx;
			else
				idx++;
		return 0;
	}

	public inline function getIntGridValueDisplayName(idx:Int) : Null<String> {
		var vd = getIntGridValueDef(idx);
		return vd==null ? null : vd.identifier==null ? '#$idx' : '${vd.identifier} #$idx';
	}

	public inline function getIntGridValueColor(idx:Int) : Null<UInt> {
		var vd = getIntGridValueDef(idx);
		return vd==null ? null : vd.color;
	}

	public function removeIntGridValue(v:Int) : Bool {
		for(i in 0...intGridValues.length)
			if( intGridValues[i].value==v ) {
				intGridValues.splice(i,1);
				return true;
			}
		return false;
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


	inline function set_tilePivotX(v) return tilePivotX = dn.M.fclamp(v, 0, 1);
	inline function set_tilePivotY(v) return tilePivotY = dn.M.fclamp(v, 0, 1);


	public inline function isAutoLayer() {
		return type==IntGrid && autoTilesetDefUid!=null || type==AutoLayer;
	}

	public function autoLayerRulesCanBeUsed() {
		if( !isAutoLayer() )
			return false;

		if( autoTilesetDefUid==null )
			return false;

		if( type==AutoLayer && autoSourceLayerDefUid==null )
			return false;

		return true;
	}

	public function hasAnyRuleUsingUnknownIntGridValues(source:LayerDef) {
		for(rg in autoRuleGroups)
		for(r in rg.rules)
			if( r.isUsingUnknownIntGridValues(source) )
				return true;
		return false;
	}

	public function hasAnyActiveRule() : Bool {
		for(rg in autoRuleGroups) {
			if( rg.active )
				for(r in rg.rules)
					if( r.active )
						return true;
		}
		return false;
	}

	public function hasRule(ruleUid:Int) : Bool {
		for(rg in autoRuleGroups)
		for(r in rg.rules)
			if( r.uid==ruleUid )
				return true;
		return false;
	}

	public inline function isRuleOptional(ruleUid:Int) {
		var r = getRule(ruleUid);
		if( r==null )
			return false;
		else {
			var rg = getParentRuleGroup(r);
			return rg!=null && rg.isOptional;
		}
	}

	public function getRule(uid:Int) : Null<AutoLayerRuleDef> {
		for( rg in autoRuleGroups )
		for( r in rg.rules )
			if( r.uid==uid )
				return r;
		return null;
	}

	public function getRuleGroup(rgUid:Int) : Null<AutoLayerRuleGroup> {
		for( rg in autoRuleGroups )
			if( rg.uid==rgUid )
				return rg;
		return null;
	}

	public function getParentRuleGroup(r:AutoLayerRuleDef) : Null<AutoLayerRuleGroup> {
		for( rg in autoRuleGroups )
		for( rr in rg.rules )
			if( rr.uid==r.uid )
				return rg;
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
			isOptional: false,
			rules: [],
		}
		if( index!=null )
			autoRuleGroups.insert(index, rg);
		else
			autoRuleGroups.push(rg);
		return rg;
	}

	public function duplicateRule(p:data.Project, rg:AutoLayerRuleGroup, r:AutoLayerRuleDef) {
		return pasteRule( p, rg, Clipboard.createTemp(CRule,r.toJson()) );
	}

	public function pasteRule(p:data.Project, rg:AutoLayerRuleGroup, c:Clipboard, ?after:AutoLayerRuleDef) : Null<AutoLayerRuleDef> {
		if( !c.is(CRule) )
			return null;

		var json : ldtk.Json.AutoRuleDef = c.getParsedJson();
		var copy = AutoLayerRuleDef.fromJson( p.jsonVersion, json );
		copy.uid = p.makeUniqueIdInt();
		if( after==null )
			rg.rules.push(copy);
		else
			rg.rules.insert( dn.Lib.getArrayIndex(after, rg.rules)+1, copy );

		p.tidy();
		return copy;
	}

	public function duplicateRuleGroup(p:data.Project, rg:AutoLayerRuleGroup) {
		return pasteRuleGroup( p, Clipboard.createTemp(CRuleGroup,toJsonRuleGroup(rg)) );
	}

	public function pasteRuleGroup(p:data.Project, c:Clipboard, ?after:AutoLayerRuleGroup) : Null<AutoLayerRuleGroup> {
		if( !c.is(CRuleGroup) )
			return null;

		var json : ldtk.Json.AutoLayerRuleGroupJson = c.getParsedJson();
		var copy = parseJsonRuleGroup( p.jsonVersion, json );
		copy.uid = p.makeUniqueIdInt();
		for(r in copy.rules)
			r.uid = p.makeUniqueIdInt();

		p.tidy();
		return copy;
	}

	public inline function iterateActiveRulesInDisplayOrder( li:data.inst.LayerInstance, cbEachRule:(r:AutoLayerRuleDef)->Void ) {
		var ruleGroupIdx = autoRuleGroups.length-1;
		while( ruleGroupIdx>=0 ) {
			// Groups
			if( li.isRuleGroupActiveHere(autoRuleGroups[ruleGroupIdx]) ) {
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

	public inline function iterateActiveRulesInEvalOrder( li:data.inst.LayerInstance, cbEachRule:(r:AutoLayerRuleDef)->Void ) {
		for(rg in autoRuleGroups)
			if( li.isRuleGroupActiveHere(rg) )
				for(r in rg.rules)
					if( r.active)
						cbEachRule(r);
	}

	public function tidy(p:data.Project) {
		// Lost tileset
		if( tilesetDefUid!=null && p.defs.getTilesetDef(tilesetDefUid)==null ) {
			App.LOG.add("tidy", 'Removed lost tileset in $this');
			tilesetDefUid = null;
		}

		// Lost auto-layer tileset
		if( autoTilesetDefUid!=null && p.defs.getTilesetDef(autoTilesetDefUid)==null ) {
			App.LOG.add("tidy", 'Removed lost autoTileset in $this');
			autoTilesetDefUid = null;
			// for(rg in autoRuleGroups)
			// for(r in rg.rules)
			// 	r.tileIds = [];
		}

		// Lost source intGrid layer
		if( autoSourceLayerDefUid!=null && p.defs.getLayerDef(autoSourceLayerDefUid)==null ) {
			autoSourceLayerDefUid = null;
			// for(rg in autoRuleGroups)
			// for(r in rg.rules)
			// 	r.tileIds = [];
		}
	}
}