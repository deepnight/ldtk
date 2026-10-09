package data;

import data.DataTypes;

/**
 * Runtime-only configuration for the RondeI33 LDtk fork.
 *
 * Configuration is stored beside the project in `<project>.ldtk-fork.json` and is NEVER
 * serialized into the LDtk project/level schema. This deliberately keeps files readable by
 * stock LDtk 1.5.3 and stock importers.
 */
class ForkConfig {
	public static inline var FORMAT = 1;

	var project : Project;
	var trackedEntities : Map<String, Dynamic> = new Map();

	public function new(p:Project) {
		project = p;
	}

	public inline function getPath() : String {
		return project.filePath.full + "-fork.json";
	}

	static inline function getDyn(o:Dynamic, field:String) : Dynamic {
		return o==null ? null : Reflect.field(o, field);
	}

	static function getArray(o:Dynamic, field:String) : Array<Dynamic> {
		var v = getDyn(o, field);
		return v==null ? [] : cast v;
	}

	static function getInt(o:Dynamic, field:String, ?fallback:Null<Int>) : Null<Int> {
		var v = getDyn(o, field);
		if( v==null )
			return fallback;
		var parsed = Std.parseInt(Std.string(v));
		return M.isValidNumber(parsed) ? parsed : fallback;
	}

	static function getFloat(o:Dynamic, field:String, ?fallback:Null<Float>) : Null<Float> {
		var v = getDyn(o, field);
		if( v==null )
			return fallback;
		var parsed = Std.parseFloat(Std.string(v));
		return M.isValidNumber(parsed) ? parsed : fallback;
	}

	static inline function cloneJson(v:Dynamic) : Dynamic {
		return v==null ? null : haxe.Json.parse(haxe.Json.stringify(v));
	}

	static function sameValue(a:Dynamic, b:Dynamic) {
		if( a==null || b==null )
			return a==b;
		return Std.string(a)==Std.string(b);
	}

	function resolveEntityUid(uid:Null<Int>, identifier:Null<String>) : Null<Int> {
		if( uid!=null && project.defs.getEntityDef(uid)!=null )
			return uid;
		if( identifier!=null )
			for(ed in project.defs.entities)
				if( ed.identifier==identifier )
					return ed.uid;
		return null;
	}

	function resolveFieldUid(ed:data.def.EntityDef, uid:Null<Int>, identifier:Null<String>) : Null<Int> {
		if( uid!=null && ed.getFieldDef(uid)!=null )
			return uid;
		if( identifier!=null )
			for(fd in ed.fieldDefs)
				if( fd.identifier==identifier )
					return fd.uid;
		return null;
	}

	function resolveLayerUid(uid:Null<Int>, identifier:Null<String>) : Null<Int> {
		if( uid!=null && project.defs.getLayerDef(uid)!=null )
			return uid;
		if( identifier!=null )
			for(ld in project.defs.layers)
				if( ld.identifier==identifier )
					return ld.uid;
		return null;
	}

	function resolveTilesetUid(uid:Null<Int>, identifier:Null<String>) : Null<Int> {
		if( uid!=null && project.defs.getTilesetDef(uid)!=null )
			return uid;
		if( identifier!=null )
			for(td in project.defs.tilesets)
				if( td.identifier==identifier )
					return td.uid;
		return null;
	}

	function normalizeAppearance(ed:data.def.EntityDef, raw:Dynamic) {
		var out = cloneJson(raw);
		var uid = resolveFieldUid(ed, getInt(out,"whenFieldUid"), getDyn(out,"whenFieldIdentifier"));
		if( uid!=null )
			Reflect.setField(out, "whenFieldUid", uid);

		var rect = getDyn(out,"tileRect");
		if( rect!=null ) {
			var tdUid = resolveTilesetUid(getInt(rect,"tilesetUid"), getDyn(rect,"tilesetIdentifier"));
			if( tdUid!=null )
				Reflect.setField(rect,"tilesetUid",tdUid);
		}
		return out;
	}

	function normalizeStamp(ed:data.def.EntityDef, raw:Dynamic) {
		var out = cloneJson(raw);
		var layerUid = resolveLayerUid(getInt(out,"layerDefUid"), getDyn(out,"layerIdentifier"));
		if( layerUid!=null )
			Reflect.setField(out,"layerDefUid",layerUid);

		var whenUid = resolveFieldUid(ed, getInt(out,"whenFieldUid"), getDyn(out,"whenFieldIdentifier"));
		if( whenUid!=null )
			Reflect.setField(out,"whenFieldUid",whenUid);

		for(tile in getArray(out,"tiles")) {
			var tdUid = resolveTilesetUid(getInt(tile,"tilesetUid"), getDyn(tile,"tilesetIdentifier"));
			if( tdUid!=null )
				Reflect.setField(tile,"tilesetUid",tdUid);
			if( getDyn(tile,"flips")==null )
				Reflect.setField(tile,"flips",0);
		}
		return out;
	}

	function normalizeEnumFilter(ed:data.def.EntityDef, raw:Dynamic) {
		var out = cloneJson(raw);
		var uid = resolveFieldUid(ed, getInt(out,"whenFieldUid"), getDyn(out,"whenFieldIdentifier"));
		if( uid!=null )
			Reflect.setField(out,"whenFieldUid",uid);
		return out;
	}

	public function load() {
		trackedEntities = new Map();

		// Clear all sidecar-only runtime state. Legacy embedded autoChildren are intentionally kept
		// until/unless the sidecar contains an explicit autoChildren entry, allowing one-time migration.
		for(ed in project.defs.entities) {
			ed.appearanceOverrides = [];
			ed.tileStamps = [];
			for(fd in ed.fieldDefs) {
				fd.visibleWhenFieldUid = null;
				fd.visibleWhenValues = [];
				fd.enumValueFilter = [];
			}
		}

		var path = getPath();
		if( !NT.fileExists(path) ) {
			var hasLegacy = false;
			for(ed in project.defs.entities)
				if( ed.autoChildren.length>0 ) {
					hasLegacy = true;
					break;
				}
			if( hasLegacy )
				save();
			return;
		}

		try {
			var root : Dynamic = haxe.Json.parse(NT.readFileString(path));
			var entities = getDyn(root,"entities");
			if( entities==null )
				return;

			var remapped = false;
			for(key in Reflect.fields(entities)) {
				var cfg = Reflect.field(entities,key);
				var keyUid = Std.parseInt(key);
				var resolvedUid = resolveEntityUid(M.isValidNumber(keyUid) ? keyUid : null, getDyn(cfg,"identifier"));
				if( resolvedUid==null ) {
					App.LOG.add("fork", 'Ignoring fork config for missing entity "$key"');
					continue;
				}
				if( !M.isValidNumber(keyUid) || resolvedUid!=keyUid )
					remapped = true;

				var ed = project.defs.getEntityDef(resolvedUid);

				if( Reflect.hasField(cfg,"autoChildren") ) {
					ed.autoChildren = [];
					for(raw in getArray(cfg,"autoChildren")) {
						var childUid = resolveEntityUid(getInt(raw,"entityDefUid"), getDyn(raw,"entityDefIdentifier"));
						if( childUid==null )
							continue;
						var ac = ed.createAutoChild(childUid);
						ac.offsetX = getInt(raw,"offsetX",0);
						ac.offsetY = getInt(raw,"offsetY",0);
						ac.count = M.imax(1,getInt(raw,"count",1));
						ac.spacingX = getInt(raw,"spacingX",0);
						ac.spacingY = getInt(raw,"spacingY",0);
						ac.linkFieldUid = resolveFieldUid(ed, getInt(raw,"linkFieldUid"), getDyn(raw,"linkFieldIdentifier"));

						var childDef = project.defs.getEntityDef(childUid);
						for(pr in getArray(raw,"fieldPresets")) {
							var fieldUid = childDef==null ? null : resolveFieldUid(childDef, getInt(pr,"fieldDefUid"), getDyn(pr,"fieldIdentifier"));
							if( fieldUid!=null )
								ac.fieldPresets.push({ fieldDefUid:fieldUid, value:getDyn(pr,"value") });
						}
					}
				}

				ed.appearanceOverrides = getArray(cfg,"appearanceOverrides").map(raw->normalizeAppearance(ed,raw));
				ed.tileStamps = getArray(cfg,"tileStamps").map(raw->normalizeStamp(ed,raw));

				var fields = getDyn(cfg,"fields");
				if( fields!=null )
					for(fieldKey in Reflect.fields(fields)) {
						var fcfg = Reflect.field(fields,fieldKey);
						var keyFieldUid = Std.parseInt(fieldKey);
						var fdUid = resolveFieldUid(ed, M.isValidNumber(keyFieldUid) ? keyFieldUid : null, getDyn(fcfg,"identifier"));
						if( fdUid==null )
							continue;
						var fd = ed.getFieldDef(fdUid);
						fd.visibleWhenFieldUid = resolveFieldUid(ed, getInt(fcfg,"visibleWhenFieldUid"), getDyn(fcfg,"visibleWhenFieldIdentifier"));
						fd.visibleWhenValues = getArray(fcfg,"visibleWhenValues");
						fd.enumValueFilter = getArray(fcfg,"enumValueFilter").map(raw->normalizeEnumFilter(ed,raw));
					}
			}

			if( remapped )
				save();
		}
		catch(err:Dynamic) {
			App.LOG.error('Failed to load fork sidecar "$path": '+Std.string(err));
		}
	}

	function entityIdentifier(uid:Null<Int>) : Null<String> {
		var ed = uid==null ? null : project.defs.getEntityDef(uid);
		return ed==null ? null : ed.identifier;
	}

	function fieldIdentifier(ed:data.def.EntityDef, uid:Null<Int>) : Null<String> {
		var fd = uid==null ? null : ed.getFieldDef(uid);
		return fd==null ? null : fd.identifier;
	}

	function layerIdentifier(uid:Null<Int>) : Null<String> {
		var ld = uid==null ? null : project.defs.getLayerDef(uid);
		return ld==null ? null : ld.identifier;
	}

	function tilesetIdentifier(uid:Null<Int>) : Null<String> {
		var td = uid==null ? null : project.defs.getTilesetDef(uid);
		return td==null ? null : td.identifier;
	}

	function enrichAppearance(ed:data.def.EntityDef, raw:Dynamic) : Dynamic {
		var out = cloneJson(raw);
		var uid = getInt(out,"whenFieldUid");
		Reflect.setField(out,"whenFieldIdentifier",fieldIdentifier(ed,uid));
		var rect = getDyn(out,"tileRect");
		if( rect!=null )
			Reflect.setField(rect,"tilesetIdentifier",tilesetIdentifier(getInt(rect,"tilesetUid")));
		return out;
	}

	function enrichStamp(ed:data.def.EntityDef, raw:Dynamic) : Dynamic {
		var out = cloneJson(raw);
		Reflect.setField(out,"layerIdentifier",layerIdentifier(getInt(out,"layerDefUid")));
		Reflect.setField(out,"whenFieldIdentifier",fieldIdentifier(ed,getInt(out,"whenFieldUid")));
		for(tile in getArray(out,"tiles"))
			Reflect.setField(tile,"tilesetIdentifier",tilesetIdentifier(getInt(tile,"tilesetUid")));
		return out;
	}

	function enrichEnumFilter(ed:data.def.EntityDef, raw:Dynamic) : Dynamic {
		var out = cloneJson(raw);
		Reflect.setField(out,"whenFieldIdentifier",fieldIdentifier(ed,getInt(out,"whenFieldUid")));
		return out;
	}

	public function save() {
		if( project.filePath==null || project.filePath.full==null || project.filePath.full.length==0 )
			return;

		var entities : Dynamic = {};
		for(ed in project.defs.entities) {
			var fields : Dynamic = {};
			var hasFields = false;
			for(fd in ed.fieldDefs)
				if( fd.visibleWhenFieldUid!=null || fd.visibleWhenValues.length>0 || fd.enumValueFilter.length>0 ) {
					hasFields = true;
					var filters = fd.enumValueFilter.map(raw->enrichEnumFilter(ed,raw));
					Reflect.setField(fields, Std.string(fd.uid), {
						identifier: fd.identifier,
						visibleWhenFieldUid: fd.visibleWhenFieldUid,
						visibleWhenFieldIdentifier: fieldIdentifier(ed,fd.visibleWhenFieldUid),
						visibleWhenValues: fd.visibleWhenValues,
						enumValueFilter: filters,
					});
				}

			if( ed.autoChildren.length==0 && ed.appearanceOverrides.length==0 && ed.tileStamps.length==0 && !hasFields )
				continue;

			var autoChildren : Array<Dynamic> = [];
			for(ac in ed.autoChildren) {
				var childDef = project.defs.getEntityDef(ac.entityDefUid);
				var presets : Array<Dynamic> = [];
				for(pr in ac.fieldPresets)
					presets.push({
						fieldDefUid: pr.fieldDefUid,
						fieldIdentifier: childDef==null ? null : fieldIdentifier(childDef,pr.fieldDefUid),
						value: pr.value,
					});
				autoChildren.push({
					entityDefUid: ac.entityDefUid,
					entityDefIdentifier: entityIdentifier(ac.entityDefUid),
					offsetX: ac.offsetX,
					offsetY: ac.offsetY,
					count: ac.count,
					spacingX: ac.spacingX,
					spacingY: ac.spacingY,
					linkFieldUid: ac.linkFieldUid,
					linkFieldIdentifier: fieldIdentifier(ed,ac.linkFieldUid),
					fieldPresets: presets,
				});
			}

			Reflect.setField(entities, Std.string(ed.uid), {
				identifier: ed.identifier,
				autoChildren: autoChildren,
				appearanceOverrides: ed.appearanceOverrides.map(raw->enrichAppearance(ed,raw)),
				tileStamps: ed.tileStamps.map(raw->enrichStamp(ed,raw)),
				fields: fields,
			});
		}

		var root : Dynamic = {
			format: FORMAT,
			projectIid: project.iid,
			entities: entities,
		};
		try {
			NT.writeFileString(getPath(), haxe.Json.stringify(root,null,"\t"));
		}
		catch(err:Dynamic) {
			App.LOG.error('Failed to save fork sidecar "${getPath()}": '+Std.string(err));
		}
	}

	function getFieldValue(ei:data.inst.EntityInstance, fieldUid:Int) : Dynamic {
		var fd = ei.def.getFieldDef(fieldUid);
		if( fd==null )
			return null;
		var fi = ei.getFieldInstance(fd,true);
		return fi==null ? null : fi.toJson().__value;
	}

	function matchesField(ei:data.inst.EntityInstance, fieldUid:Null<Int>, expected:Dynamic) {
		if( fieldUid==null )
			return true;
		var fd = ei.def.getFieldDef(fieldUid);
		if( fd==null )
			return false;
		return sameValue(getFieldValue(ei,fieldUid), expected);
	}

	public function isFieldVisible(ei:Null<data.inst.EntityInstance>, fd:data.def.FieldDef) {
		if( ei==null || fd.visibleWhenFieldUid==null || fd.visibleWhenValues.length==0 )
			return true;
		if( ei.def.getFieldDef(fd.visibleWhenFieldUid)==null )
			return true;
		var actual = getFieldValue(ei,fd.visibleWhenFieldUid);
		for(expected in fd.visibleWhenValues)
			if( sameValue(actual,expected) )
				return true;
		return false;
	}

	public function isEnumValueAllowed(ei:Null<data.inst.EntityInstance>, fd:data.def.FieldDef, valueId:String) {
		if( ei==null || fd.enumValueFilter.length==0 )
			return true;
		var matchedRule = false;
		for(rule in fd.enumValueFilter) {
			var whenUid = getInt(rule,"whenFieldUid");
			if( matchesField(ei,whenUid,getDyn(rule,"whenValue")) ) {
				matchedRule = true;
				for(allowed in getArray(rule,"allowedEnumValueIds"))
					if( Std.string(allowed)==valueId )
						return true;
			}
		}
		return !matchedRule;
	}

	public function hasValidationError(ei:data.inst.EntityInstance) {
		for(fd in ei.def.fieldDefs)
			if( fd.enumValueFilter.length>0 )
				switch fd.type {
					case F_Enum(_):
						var fi = ei.getFieldInstance(fd,true);
						for(i in 0...fi.getArrayLength()) {
							var v = fi.getEnumValue(i);
							if( v!=null && !isEnumValueAllowed(ei,fd,v) )
								return true;
						}
					case _:
				}
		return false;
	}

	public function getAppearance(ei:data.inst.EntityInstance) : Dynamic {
		for(raw in ei.def.appearanceOverrides)
			if( matchesField(ei,getInt(raw,"whenFieldUid"),getDyn(raw,"whenValue")) )
				return raw;
		return null;
	}

	public function getAppearanceWidth(ei:data.inst.EntityInstance) : Null<Int> {
		return getInt(getAppearance(ei),"width");
	}
	public function hasAppearanceWidthOverride(ed:data.def.EntityDef) {
		for(raw in ed.appearanceOverrides)
			if( getDyn(raw,"width")!=null )
				return true;
		return false;
	}
	public function getAppearanceHeight(ei:data.inst.EntityInstance) : Null<Int> {
		return getInt(getAppearance(ei),"height");
	}
	public function hasAppearanceHeightOverride(ed:data.def.EntityDef) {
		for(raw in ed.appearanceOverrides)
			if( getDyn(raw,"height")!=null )
				return true;
		return false;
	}
	public function getAppearancePivotX(ei:data.inst.EntityInstance) : Null<Float> {
		return getFloat(getAppearance(ei),"pivotX");
	}
	public function getAppearancePivotY(ei:data.inst.EntityInstance) : Null<Float> {
		return getFloat(getAppearance(ei),"pivotY");
	}
	public function getAppearanceTile(ei:data.inst.EntityInstance) : Null<ldtk.Json.TilesetRect> {
		var a = getAppearance(ei);
		return a==null || getDyn(a,"tileRect")==null ? null : cast getDyn(a,"tileRect");
	}
	public function getAppearanceColor(ei:data.inst.EntityInstance) : Null<Int> {
		var a = getAppearance(ei);
		var raw = getDyn(a,"color");
		if( raw==null )
			return null;
		return Type.typeof(raw)==TInt ? cast raw : dn.legacy.Color.hexToInt(Std.string(raw));
	}

	function stampIsActive(ei:data.inst.EntityInstance, stamp:Dynamic) {
		return matchesField(ei,getInt(stamp,"whenFieldUid"),getDyn(stamp,"whenValue"));
	}

	function findStampLayer(ei:data.inst.EntityInstance, stamp:Dynamic) : Null<data.inst.LayerInstance> {
		var uid = getInt(stamp,"layerDefUid");
		if( uid==null )
			return null;
		for(li in ei._li.level.layerInstances)
			if( li.layerDefUid==uid && li.def.type==Tiles )
				return li;
		return null;
	}

	function markGrid(li:data.inst.LayerInstance, cx:Int, cy:Int) {
		if( Editor.exists() && Editor.ME.curLevel==li.level )
			Editor.ME.curLevelTimeline.markGridChange(li,cx,cy);
	}

	function paintStampAt(ei:data.inst.EntityInstance, stamp:Dynamic, px:Int, py:Int, touched:Map<Int,data.inst.LayerInstance>) {
		var li = findStampLayer(ei,stamp);
		if( li==null )
			return;
		var grid = li.def.gridSize;
		var baseCx = M.round(px/grid);
		var baseCy = M.round(py/grid);
		for(tile in getArray(stamp,"tiles")) {
			var tileId = getInt(tile,"tileId");
			if( tileId==null )
				continue;
			var tilesetUid = getInt(tile,"tilesetUid",li.getTilesetUid());
			if( tilesetUid!=li.getTilesetUid() ) {
				App.LOG.add("fork", 'Skipped tile stamp: tileset $tilesetUid does not match layer ${li.getTilesetUid()}');
				continue;
			}
			var cx = baseCx + getInt(tile,"dx",0);
			var cy = baseCy + getInt(tile,"dy",0);
			if( !li.isValid(cx,cy) )
				continue;
			markGrid(li,cx,cy);
			li.removeAllGridTiles(cx,cy,false);
			li.addGridTile(cx,cy,tileId,getInt(tile,"flips",0),false,false);
			touched.set(li.layerDefUid,li);
		}
	}

	function eraseStampAt(ei:data.inst.EntityInstance, stamp:Dynamic, px:Int, py:Int, touched:Map<Int,data.inst.LayerInstance>) {
		var li = findStampLayer(ei,stamp);
		if( li==null )
			return;
		var grid = li.def.gridSize;
		var baseCx = M.round(px/grid);
		var baseCy = M.round(py/grid);
		for(tile in getArray(stamp,"tiles")) {
			var tileId = getInt(tile,"tileId");
			if( tileId==null )
				continue;
			var cx = baseCx + getInt(tile,"dx",0);
			var cy = baseCy + getInt(tile,"dy",0);
			if( !li.isValid(cx,cy) )
				continue;
			var stack = li.getGridTileStack(cx,cy);
			if( stack.length==1 && stack[0].tileId==tileId && stack[0].flips==getInt(tile,"flips",0) ) {
				markGrid(li,cx,cy);
				li.removeAllGridTiles(cx,cy,false);
				touched.set(li.layerDefUid,li);
			}
		}
	}

	static function touchedToArray(touched:Map<Int,data.inst.LayerInstance>) {
		var all = [];
		for(li in touched)
			all.push(li);
		return all;
	}

	public function paintEntityStamps(ei:data.inst.EntityInstance) : Array<data.inst.LayerInstance> {
		var touched : Map<Int,data.inst.LayerInstance> = new Map();
		for(stamp in ei.def.tileStamps)
			if( stampIsActive(ei,stamp) )
				paintStampAt(ei,stamp,ei.x,ei.y,touched);
		trackEntity(ei);
		return touchedToArray(touched);
	}

	public function eraseEntityStamps(ei:data.inst.EntityInstance) : Array<data.inst.LayerInstance> {
		var touched : Map<Int,data.inst.LayerInstance> = new Map();
		for(stamp in ei.def.tileStamps)
			if( stampIsActive(ei,stamp) )
				eraseStampAt(ei,stamp,ei.x,ei.y,touched);
		trackedEntities.remove(ei.iid);
		return touchedToArray(touched);
	}

	public function trackEntity(ei:data.inst.EntityInstance) {
		var gates = [];
		for(stamp in ei.def.tileStamps)
			gates.push(stampIsActive(ei,stamp));
		trackedEntities.set(ei.iid, { x:ei.x, y:ei.y, gates:gates });
	}

	public function syncTrackedEntity(ei:data.inst.EntityInstance) : Array<data.inst.LayerInstance> {
		var old = trackedEntities.get(ei.iid);
		if( old==null ) {
			trackEntity(ei);
			return [];
		}

		var touched : Map<Int,data.inst.LayerInstance> = new Map();
		var oldGates : Array<Bool> = cast old.gates;
		var moved = old.x!=ei.x || old.y!=ei.y;
		for(i in 0...ei.def.tileStamps.length) {
			var stamp = ei.def.tileStamps[i];
			var wasActive = i<oldGates.length ? oldGates[i] : false;
			var isActive = stampIsActive(ei,stamp);
			if( moved ) {
				if( wasActive )
					eraseStampAt(ei,stamp,old.x,old.y,touched);
				if( isActive )
					paintStampAt(ei,stamp,ei.x,ei.y,touched);
			}
			else if( wasActive!=isActive ) {
				if( wasActive )
					eraseStampAt(ei,stamp,ei.x,ei.y,touched);
				else
					paintStampAt(ei,stamp,ei.x,ei.y,touched);
			}
		}
		trackEntity(ei);
		return touchedToArray(touched);
	}

	public function restampLevel(level:data.Level) : Array<data.inst.LayerInstance> {
		var touched : Map<Int,data.inst.LayerInstance> = new Map();
		for(li in level.layerInstances)
			if( li.def.type==Entities )
				for(ei in li.entityInstances)
					for(stamp in ei.def.tileStamps)
						if( stampIsActive(ei,stamp) )
							paintStampAt(ei,stamp,ei.x,ei.y,touched);
		for(li in level.layerInstances)
			if( li.def.type==Entities )
				for(ei in li.entityInstances)
					trackEntity(ei);
		return touchedToArray(touched);
	}
}
