package misc;

import data.DataTypes;
import data.def.TilesetDef;

typedef AtlasComposeSource = {
	var tilesetUid : Int;
	var tileIds : Array<Int>;
}

typedef AtlasComposeResult = {
	var destinationUid : Int;
	var destinationIdentifier : String;
	var movedTileCount : Int;
	var removedTilesetCount : Int;
	var generatedFiles : Array<String>;
}

private typedef PackUnit = {
	var sourceUid : Int;
	var ids : Array<Int>;
	var minX : Int;
	var minY : Int;
	var wid : Int;
	var hei : Int;
	var outX : Int;
	var outY : Int;
}

private typedef PackResult = {
	var pixels : hxd.Pixels;
	var cWid : Int;
	var cHei : Int;
	var mappings : Map<Int, Map<Int,Int>>;
}

private typedef SourceMigration = {
	var old : TilesetDef;
	var selected : Map<Int,Bool>;
	var selectedMap : Map<Int,Int>;
	var remainingMap : Map<Int,Int>;
	var remainder : Null<TilesetDef>;
}

private typedef TileTarget = {
	var td : TilesetDef;
	var tileId : Int;
}

/**
 * Selectively packs tile cells from multiple LDtk tilesets into one generated
 * atlas and migrates LDtk references. Source images are never overwritten:
 * compacted remainders are generated under .ldtk-atlas/ and keep the original
 * LDtk tileset identifier after migration.
 *
 * A single generated atlas has one tileGridSize, so all source tilesets in one
 * compose operation must use the same grid size.
 */
class TilesetAtlasComposer {
	static inline var OUTPUT_DIR = ".ldtk-atlas";

	static function tileKey(uid:Int, tid:Int) return uid+":"+tid;

	static function contains(m:Map<Int,Bool>, id:Int) return m.exists(id) && m.get(id)==true;

	static function mapKeys(m:Map<Int,Bool>) : Array<Int> {
		var out = [];
		for(k in m.keys()) out.push(k);
		out.sort(Reflect.compare);
		return out;
	}

	static function allTileIds(td:TilesetDef) : Array<Int> {
		var all = [];
		for(i in 0...td.cWid*td.cHei)
			all.push(i);
		return all;
	}

	static function validIds(td:TilesetDef, ids:Array<Int>) : Array<Int> {
		var seen : Map<Int,Bool> = new Map();
		var out = [];
		for(id in ids)
			if( id>=0 && id<td.cWid*td.cHei && !seen.exists(id) ) {
				seen.set(id,true);
				out.push(id);
			}
		out.sort(Reflect.compare);
		return out;
	}

	static function addGroup(groups:Array<Array<Int>>, td:TilesetDef, ids:Array<Int>) {
		var clean = validIds(td, ids);
		if( clean.length>1 )
			groups.push(clean);
	}

	static function collectProtectedGroups(project:data.Project, td:TilesetDef) : Array<Array<Int>> {
		var groups : Array<Array<Int>> = [];

		// Saved multi-tile selections / stamps.
		for(sel in td.savedSelections)
			addGroup(groups, td, sel.ids);

		// Entity display and UI tiles.
		for(ed in project.defs.entities) {
			if( ed.tileRect!=null && ed.tileRect.tilesetUid==td.uid )
				addGroup(groups, td, td.getTileIdsFromRect(ed.tileRect));
			if( ed.uiTileRect!=null && ed.uiTileRect.tilesetUid==td.uid )
				addGroup(groups, td, td.getTileIdsFromRect(ed.uiTileRect));
		}

		// Enum icons.
		for(en in project.defs.enums)
			for(v in en.values)
				if( v.tileRect!=null && v.tileRect.tilesetUid==td.uid )
					addGroup(groups, td, td.getTileIdsFromRect(v.tileRect));

		// IntGrid display tiles.
		for(ld in project.defs.layers)
			for(iv in ld.getAllIntGridValues())
				if( iv.tile!=null && iv.tile.tilesetUid==td.uid )
					addGroup(groups, td, td.getTileIdsFromRect(iv.tile));

		// Auto-layer stamps must remain spatially intact.
		for(ld in project.defs.layers)
			if( ld.isAutoLayer() && ld.tilesetDefUid==td.uid )
				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
				for(ids in r.tileRectsIds)
					addGroup(groups, td, ids);

		// Tile field defaults and actual values.
		function collectFieldDef(fd:data.def.FieldDef) {
			switch fd.type {
				case F_Tile:
					if( fd.tilesetUid==td.uid ) {
						var r = fd.getTileRectDefaultObj();
						if( r!=null ) addGroup(groups, td, td.getTileIdsFromRect(r));
					}
				case _:
			}
		}
		for(fd in project.defs.levelFields) collectFieldDef(fd);
		for(ed in project.defs.entities)
			for(fd in ed.fieldDefs) collectFieldDef(fd);

		project.iterateAllFieldInstances(F_Tile, fi->{
			if( fi.def.tilesetUid==td.uid )
				for(i in 0...fi.getArrayLength()) {
					var r = fi.getTileRectObj(i);
					if( r!=null ) addGroup(groups, td, td.getTileIdsFromRect(r));
				}
		});

		return groups;
	}

	static function expandSelection(td:TilesetDef, selected:Map<Int,Bool>, groups:Array<Array<Int>>) {
		var changed = true;
		while( changed ) {
			changed = false;
			for(group in groups) {
				var touches = false;
				for(id in group)
					if( contains(selected,id) ) {
						touches = true;
						break;
					}
				if( touches )
					for(id in group)
						if( !contains(selected,id) ) {
							selected.set(id,true);
							changed = true;
						}
			}
		}
	}

	/** 1=moved, 2=remaining, 3=split. */
	static function classify(ids:Array<Int>, selected:Map<Int,Bool>) : Int {
		var out = 0;
		for(id in ids)
			out |= contains(selected,id) ? 1 : 2;
		return out;
	}

	static function fieldDefRefs(project:data.Project, td:TilesetDef, fd:data.def.FieldDef) : Array<Int> {
		var ids : Array<Int> = [];
		if( fd.tilesetUid!=td.uid )
			return ids;
		var d = fd.getTileRectDefaultObj();
		if( d!=null ) ids = ids.concat(td.getTileIdsFromRect(d));
		project.iterateAllFieldInstances(F_Tile, fi->{
			if( fi.def==fd )
				for(i in 0...fi.getArrayLength()) {
					var r = fi.getTileRectObj(i);
					if( r!=null ) ids = ids.concat(td.getTileIdsFromRect(r));
				}
		});
		return validIds(td,ids);
	}

	static function preflight(project:data.Project, td:TilesetDef, selected:Map<Int,Bool>) {
		// Tile layers have one tileset at layer/instance level. To avoid silently
		// splitting one layer across two atlases, every used tile on a layer must
		// go to the same side of the migration.
		for(ld in project.defs.layers)
			if( ld.type==Tiles ) {
				var ids : Array<Int> = [];
				var relevant = ld.tilesetDefUid==td.uid;
				for(w in project.worlds)
				for(l in w.levels) {
					var li = l.getLayerInstance(ld);
					if( li!=null && li.getTilesetUid()==td.uid ) {
						relevant = true;
						for(stack in li.gridTiles)
							for(t in stack) ids.push(t.tileId);
					}
				}
				if( relevant && classify(validIds(td,ids), selected)==3 )
					throw 'Layer "${ld.identifier}" uses both selected and remaining tiles from "${td.identifier}". Move all tiles used by this layer together, or leave them together.';
			}

		// Auto-layer rules share one tileset definition.
		for(ld in project.defs.layers)
			if( ld.isAutoLayer() && ld.tilesetDefUid==td.uid ) {
				var ids : Array<Int> = [];
				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
				for(stamp in r.tileRectsIds)
					ids = ids.concat(stamp);
				if( classify(validIds(td,ids), selected)==3 )
					throw 'Auto-layer "${ld.identifier}" uses both selected and remaining tiles from "${td.identifier}". Its rule output must stay in one tileset.';
			}

		// One EnumDef has one icon tileset.
		for(en in project.defs.enums)
			if( en.iconTilesetUid==td.uid ) {
				var ids : Array<Int> = [];
				for(v in en.values)
					if( v.tileRect!=null && v.tileRect.tilesetUid==td.uid )
						ids = ids.concat(td.getTileIdsFromRect(v.tileRect));
				if( classify(validIds(td,ids), selected)==3 )
					throw 'Enum "${en.identifier}" has icons on both sides of this move. All icons of one enum must remain in a single tileset.';
			}

		// One F_Tile definition also has one tileset UID.
		function checkField(fd:data.def.FieldDef) {
			switch fd.type {
				case F_Tile:
					if( fd.tilesetUid==td.uid ) {
						var ids = fieldDefRefs(project,td,fd);
						if( classify(ids,selected)==3 )
							throw 'Tile field "${fd.identifier}" has values on both sides of this move. All values for one Tile field must remain in a single tileset.';
					}
				case _:
			}
		}
		for(fd in project.defs.levelFields) checkField(fd);
		for(ed in project.defs.entities)
			for(fd in ed.fieldDefs) checkField(fd);
	}

	static function buildUnits(td:TilesetDef, ids:Array<Int>, groups:Array<Array<Int>>, preserveWholeShape=false) : Array<PackUnit> {
		// Shape-preserving mode keeps a whole set of cells at their original
		// relative coordinates. Empty holes inside the bounding box stay empty.
		// This is used both for destination selections and for remainder atlases:
		// remainders may trim fully empty outer rows/columns, but never collapse
		// internal gaps or rearrange surviving cells.
		if( preserveWholeShape ) {
			var clean = validIds(td,ids);
			if( clean.length==0 ) return [];
			var minX = 0x3fffffff;
			var minY = 0x3fffffff;
			var maxX = -1;
			var maxY = -1;
			for(id in clean) {
				minX = dn.M.imin(minX,td.getTileCx(id));
				minY = dn.M.imin(minY,td.getTileCy(id));
				maxX = dn.M.imax(maxX,td.getTileCx(id));
				maxY = dn.M.imax(maxY,td.getTileCy(id));
			}
			return [{
				sourceUid:td.uid,
				ids:clean,
				minX:minX,
				minY:minY,
				wid:maxX-minX+1,
				hei:maxY-minY+1,
				outX:0,
				outY:0,
			}];
		}
		var allowed : Map<Int,Bool> = new Map();
		for(id in ids) allowed.set(id,true);

		var linked : Map<Int,Array<Int>> = new Map();
		for(group in groups) {
			var kept = group.filter(id->allowed.exists(id));
			if( kept.length>1 )
				for(id in kept) {
					if( !linked.exists(id) ) linked.set(id,[]);
					for(other in kept)
						if( other!=id && !linked.get(id).contains(other) ) linked.get(id).push(other);
				}
		}

		var visited : Map<Int,Bool> = new Map();
		var units : Array<PackUnit> = [];
		for(start in ids) {
			if( visited.exists(start) ) continue;
			var pending = [start];
			var component : Array<Int> = [];
			visited.set(start,true);
			while( pending.length>0 ) {
				var id = pending.pop();
				component.push(id);
				// Only explicit protected reference groups stay together. Ordinary
				// neighboring cells are independent so selected and remaining cells
				// can actually compact into a smaller atlas.
				if( linked.exists(id) )
					for(n in linked.get(id))
						if( allowed.exists(n) && !visited.exists(n) ) {
							visited.set(n,true);
							pending.push(n);
						}
			}

			var minX = 0x3fffffff;
			var minY = 0x3fffffff;
			var maxX = -1;
			var maxY = -1;
			for(id in component) {
				minX = dn.M.imin(minX,td.getTileCx(id));
				minY = dn.M.imin(minY,td.getTileCy(id));
				maxX = dn.M.imax(maxX,td.getTileCx(id));
				maxY = dn.M.imax(maxY,td.getTileCy(id));
			}
			units.push({
				sourceUid:td.uid,
				ids:component,
				minX:minX,
				minY:minY,
				wid:maxX-minX+1,
				hei:maxY-minY+1,
				outX:0,
				outY:0,
			});
		}
		return units;
	}

	static function pack(project:data.Project, grid:Int, units:Array<PackUnit>, sourceLookup:Map<Int,TilesetDef>) : PackResult {
		if( units.length==0 )
			throw "Cannot pack an empty atlas.";

		var area = 0;
		var maxWid = 1;
		for(u in units) {
			area += u.wid*u.hei;
			maxWid = dn.M.imax(maxWid,u.wid);
		}
		var targetWid = dn.M.imax(maxWid, Std.int(Math.ceil(Math.sqrt(area))));

		// Larger groups first gives a noticeably tighter shelf pack while each
		// group's internal tile layout remains untouched.
		units.sort((a,b)-> {
			var byH = Reflect.compare(b.hei,a.hei);
			return byH!=0 ? byH : Reflect.compare(b.wid,a.wid);
		});

		var x = 0;
		var y = 0;
		var rowH = 0;
		var usedWid = 0;
		for(u in units) {
			if( x>0 && x+u.wid>targetWid ) {
				y += rowH;
				x = 0;
				rowH = 0;
			}
			u.outX = x;
			u.outY = y;
			x += u.wid;
			rowH = dn.M.imax(rowH,u.hei);
			usedWid = dn.M.imax(usedWid,x);
		}
		var usedHei = y+rowH;
		usedWid = dn.M.imax(usedWid,1);
		usedHei = dn.M.imax(usedHei,1);

		var pixels = hxd.Pixels.alloc(usedWid*grid, usedHei*grid, RGBA);
		pixels.clear(0x00000000);
		var mappings : Map<Int,Map<Int,Int>> = new Map();

		for(u in units) {
			var source = sourceLookup.get(u.sourceUid);
			if( source==null || !source.isAtlasLoaded() )
				throw 'Source tileset ${u.sourceUid} is not loaded.';
			var img = project.getOrLoadImage(source.relPath);
			if( img==null )
				throw 'Could not load source image for "${source.identifier}".';
			if( !mappings.exists(source.uid) ) mappings.set(source.uid,new Map());
			for(oldId in u.ids) {
				var relX = source.getTileCx(oldId)-u.minX;
				var relY = source.getTileCy(oldId)-u.minY;
				var dstCx = u.outX+relX;
				var dstCy = u.outY+relY;
				pixels.blit(
					dstCx*grid, dstCy*grid,
					img.pixels,
					source.getTileSourceX(oldId), source.getTileSourceY(oldId),
					grid, grid
				);
				mappings.get(source.uid).set(oldId, dstCx+dstCy*usedWid);
			}
		}

		return { pixels:pixels, cWid:usedWid, cHei:usedHei, mappings:mappings };
	}

	static function ensureOutputDir(project:data.Project) : String {
		var abs = dn.FilePath.fromDir(project.getProjectDir()+"/"+OUTPUT_DIR).full;
		if( !NT.fileExists(abs) ) NT.createDirs(abs);
		return abs;
	}

	static function uniqueIdentifier(project:data.Project, base:String) : String {
		base = data.Project.cleanupIdentifier(base,project.identifierStyle);
		if( base==null || base=="" || base=="_" ) base = "CombinedTileset";
		var id = base;
		var n = 2;
		function exists(v:String) {
			for(td in project.defs.tilesets)
				if( td.identifier==v ) return true;
			return false;
		}
		while( exists(id) ) id = base+(n++);
		return id;
	}

	static function createGeneratedTileset(project:data.Project, identifier:String, relPath:String, grid:Int, png:haxe.io.Bytes) : TilesetDef {
		var abs = project.makeAbsoluteFilePath(relPath,false);
		NT.writeFileBytes(abs,png);
		var td = project.defs.createTilesetDef();
		td.identifier = identifier;
		td.tileGridSize = grid;
		td.spacing = 0;
		td.padding = 0;
		var result = td.importAtlasImage(relPath);
		switch result {
			case Ok, RemapSuccessful, TrimmedPadding:
			case _:
				throw 'Failed to load generated atlas "$relPath": '+Std.string(result);
		}
		return td;
	}

	static function targetFor(m:SourceMigration, destination:TilesetDef, oldId:Int) : Null<TileTarget> {
		if( m.selectedMap.exists(oldId) )
			return {td:destination,tileId:m.selectedMap.get(oldId)};
		if( m.remainder!=null && m.remainingMap.exists(oldId) )
			return {td:m.remainder,tileId:m.remainingMap.get(oldId)};
		return null;
	}

	static function migrateRect(m:SourceMigration, destination:TilesetDef, rect:Null<ldtk.Json.TilesetRect>) : Null<ldtk.Json.TilesetRect> {
		if( rect==null || rect.tilesetUid!=m.old.uid )
			return rect;
		var newTd : Null<TilesetDef> = null;
		var newIds : Array<Int> = [];
		for(oldId in m.old.getTileIdsFromRect(rect)) {
			var t = targetFor(m,destination,oldId);
			if( t==null ) throw 'Lost tile reference ${m.old.identifier}#$oldId during atlas migration.';
			if( newTd==null ) newTd = t.td;
			else if( newTd.uid!=t.td.uid )
				throw 'A multi-tile rectangle from "${m.old.identifier}" would be split across two atlases.';
			newIds.push(t.tileId);
		}
		return newTd==null ? null : newTd.getTileRectFromTileIds(newIds);
	}

	static function chooseTarget(m:SourceMigration, destination:TilesetDef, ids:Array<Int>) : TilesetDef {
		var side = classify(validIds(m.old,ids),m.selected);
		if( side==1 ) return destination;
		if( side==2 && m.remainder!=null ) return m.remainder;
		if( side==0 ) return m.remainder!=null ? m.remainder : destination;
		throw 'Reference set in "${m.old.identifier}" is split across generated atlases.';
	}

	static function copyTilesetMetadata(m:SourceMigration, destination:TilesetDef) {
		// Whole-tileset organizational tags are useful on both descendants.
		for(tag in m.old.tags.iterator()) {
			destination.tags.set(tag);
			if( m.remainder!=null ) m.remainder.tags.set(tag);
		}

		// Per-tile enum tags and custom data follow their cells.
		for(oldId in 0...m.old.cWid*m.old.cHei) {
			var t = targetFor(m,destination,oldId);
			if( t==null ) continue;
			var custom = m.old.getTileCustomData(oldId);
			if( custom!=null ) t.td.setTileCustomData(t.tileId,custom);
			for(tag in m.old.getAllTagsAt(oldId))
				t.td.setTag(t.tileId,tag,true);
		}

		if( m.old.tagsSourceEnumUid!=null ) {
			if( m.remainder!=null ) m.remainder.tagsSourceEnumUid = m.old.tagsSourceEnumUid;
			var hasMovedTags = false;
			for(id in m.selected.keys())
				if( m.old.hasAnyTag(id) ) { hasMovedTags=true; break; }
			if( hasMovedTags ) {
				if( destination.tagsSourceEnumUid!=null && destination.tagsSourceEnumUid!=m.old.tagsSourceEnumUid )
					throw "Selected tiles use incompatible enum tag sources; they cannot share one destination tileset.";
				destination.tagsSourceEnumUid = m.old.tagsSourceEnumUid;
			}
		}

		// Saved selections are protected groups, therefore each one maps wholly
		// to one destination and can be recreated there.
		for(sel in m.old.savedSelections) {
			var newTd : Null<TilesetDef> = null;
			var ids : Array<Int> = [];
			for(oldId in sel.ids) {
				var t = targetFor(m,destination,oldId);
				if( t==null ) continue;
				if( newTd==null ) newTd=t.td;
				else if( newTd.uid!=t.td.uid ) throw "A saved tile selection was split during composition.";
				ids.push(t.tileId);
			}
			if( newTd!=null && ids.length>1 )
				newTd.savedSelections.push({mode:sel.mode,ids:ids});
		}
	}

	static function migrateReferences(project:data.Project, migrations:Array<SourceMigration>, destination:TilesetDef) {
		for(m in migrations) {
			// Entity display tiles.
			for(ed in project.defs.entities) {
				ed.tileRect = migrateRect(m,destination,ed.tileRect);
				ed.uiTileRect = migrateRect(m,destination,ed.uiTileRect);
				if( ed.tileRect!=null ) ed.tilesetId = ed.tileRect.tilesetUid;
			}

			// Enum icon rectangles + common icon tileset UID.
			for(en in project.defs.enums) {
				var touched = en.iconTilesetUid==m.old.uid;
				var refIds : Array<Int> = [];
				for(v in en.values) {
					if( v.tileRect!=null && v.tileRect.tilesetUid==m.old.uid )
						refIds = refIds.concat(m.old.getTileIdsFromRect(v.tileRect));
					v.tileRect = migrateRect(m,destination,v.tileRect);
				}
				if( touched ) en.iconTilesetUid = chooseTarget(m,destination,refIds).uid;
			}

			// IntGrid display tiles.
			for(ld in project.defs.layers)
				for(iv in ld.getAllIntGridValues())
					iv.tile = migrateRect(m,destination,iv.tile);

			// Tile layers and per-level overrides.
			for(ld in project.defs.layers)
				if( ld.type==Tiles ) {
					var layerIds : Array<Int> = [];
					for(w in project.worlds)
					for(l in w.levels) {
						var li = l.getLayerInstance(ld);
						if( li==null || li.getTilesetUid()!=m.old.uid ) continue;
						var ids : Array<Int> = [];
						for(stack in li.gridTiles)
							for(t in stack) ids.push(t.tileId);
						var target = chooseTarget(m,destination,ids);
						for(stack in li.gridTiles)
							for(t in stack) {
								var nt = targetFor(m,destination,t.tileId);
								if( nt==null || nt.td.uid!=target.uid ) throw "Tile-layer migration mismatch.";
								t.tileId = nt.tileId;
							}
						li.setOverrideTileset(target.uid);
						layerIds = layerIds.concat(ids);
					}
					if( ld.tilesetDefUid==m.old.uid )
						ld.tilesetDefUid = chooseTarget(m,destination,layerIds).uid;
				}

			// Auto-layer rules.
			for(ld in project.defs.layers)
				if( ld.isAutoLayer() && ld.tilesetDefUid==m.old.uid ) {
					var ids : Array<Int> = [];
					for(rg in ld.autoRuleGroups)
					for(r in rg.rules)
					for(stamp in r.tileRectsIds)
						ids = ids.concat(stamp);
					var target = chooseTarget(m,destination,ids);
					for(rg in ld.autoRuleGroups)
					for(r in rg.rules)
					for(stamp in r.tileRectsIds)
						for(i in 0...stamp.length) {
							var nt = targetFor(m,destination,stamp[i]);
							if( nt==null || nt.td.uid!=target.uid ) throw "Auto-layer migration mismatch.";
							stamp[i] = nt.tileId;
						}
					ld.tilesetDefUid = target.uid;
				}

			// Tile field definitions: migrate raw coordinate values before changing
			// the field's common tileset UID.
			function migrateField(fd:data.def.FieldDef) {
				switch fd.type {
					case F_Tile:
						if( fd.tilesetUid!=m.old.uid ) return;
						var refs = fieldDefRefs(project,m.old,fd);
						var target = chooseTarget(m,destination,refs);
						var oldDefault = fd.getTileRectDefaultObj();
						var newDefault = migrateRect(m,destination,oldDefault);
						project.iterateAllFieldInstances(F_Tile, fi->{
							if( fi.def==fd )
								for(i in 0...fi.getArrayLength()) {
									if( fi.isUsingDefault(i) ) continue;
									var nr = migrateRect(m,destination,fi.getTileRectObj(i));
									fi.parseValue(i, nr==null ? null : '${nr.x},${nr.y},${nr.w},${nr.h}');
								}
						});
						fd.tilesetUid = target.uid;
						fd.setDefault(newDefault==null ? null : '${newDefault.x},${newDefault.y},${newDefault.w},${newDefault.h}');
					case _:
				}
			}
			for(fd in project.defs.levelFields) migrateField(fd);
			for(ed in project.defs.entities)
				for(fd in ed.fieldDefs) migrateField(fd);
		}
	}

	public static function compose(project:data.Project, requestedIdentifier:String, sources:Array<AtlasComposeSource>) : AtlasComposeResult {
		if( project==null ) throw "No project is open.";
		if( sources==null || sources.length==0 ) throw "Select at least one source tileset.";

		var sourceLookup : Map<Int,TilesetDef> = new Map();
		var selectedBySource : Map<Int,Map<Int,Bool>> = new Map();
		var groupsBySource : Map<Int,Array<Array<Int>>> = new Map();
		var grid : Null<Int> = null;
		var movedCount = 0;

		for(src in sources) {
			var td = project.defs.getTilesetDef(src.tilesetUid);
			if( td==null || td.isUsingEmbedAtlas() ) throw 'Tileset UID ${src.tilesetUid} is not an editable image tileset.';
			if( !td.isAtlasLoaded() ) throw 'Tileset "${td.identifier}" could not be loaded.';
			if( grid==null ) grid=td.tileGridSize;
			else if( grid!=td.tileGridSize )
				throw 'All source tilesets must have the same tile size. "${td.identifier}" uses ${td.tileGridSize}px while this composition uses ${grid}px.';
			var ids = validIds(td,src.tileIds);
			if( ids.length==0 ) continue;
			var selected : Map<Int,Bool> = new Map();
			for(id in ids) selected.set(id,true);
			var groups = collectProtectedGroups(project,td);
			expandSelection(td,selected,groups);
			preflight(project,td,selected);
			sourceLookup.set(td.uid,td);
			selectedBySource.set(td.uid,selected);
			groupsBySource.set(td.uid,groups);
			movedCount += mapKeys(selected).length;
		}

		if( sourceLookup.keys().hasNext()==false ) throw "No tiles were selected.";

		// Enum-tagged cells can only share a destination when they use the same
		// source enum, because LDtk stores one tagsSourceEnumUid per tileset.
		var destinationTagEnum : Null<Int> = null;
		for(uid in sourceLookup.keys()) {
			var td = sourceLookup.get(uid);
			var hasMovedTags = false;
			for(id in selectedBySource.get(uid).keys())
				if( td.hasAnyTag(id) ) { hasMovedTags=true; break; }
			if( hasMovedTags && td.tagsSourceEnumUid!=null ) {
				if( destinationTagEnum==null ) destinationTagEnum=td.tagsSourceEnumUid;
				else if( destinationTagEnum!=td.tagsSourceEnumUid )
					throw "Selected tiles use different enum-tag sources. Compose those tagged tiles into separate atlases.";
			}
		}

		var destinationUnits : Array<PackUnit> = [];
		for(uid in sourceLookup.keys()) {
			var td = sourceLookup.get(uid);
			destinationUnits = destinationUnits.concat(buildUnits(td,mapKeys(selectedBySource.get(uid)),groupsBySource.get(uid),true));
		}
		var packedDestination = pack(project,grid,destinationUnits,sourceLookup);

		var outDir = ensureOutputDir(project);
		var destinationIdentifier = uniqueIdentifier(project,requestedIdentifier);
		var destRel = OUTPUT_DIR+"/"+destinationIdentifier+".png";
		var destination = createGeneratedTileset(project,destinationIdentifier,destRel,grid,packedDestination.pixels.toPNG());
		if( destinationTagEnum!=null ) destination.tagsSourceEnumUid=destinationTagEnum;
		var generatedFiles = [project.makeAbsoluteFilePath(destRel,false)];

		var migrations : Array<SourceMigration> = [];
		for(uid in sourceLookup.keys()) {
			var old = sourceLookup.get(uid);
			var selected = selectedBySource.get(uid);
			var remaining : Array<Int> = [];
			for(id in allTileIds(old))
				if( !contains(selected,id) ) remaining.push(id);

			var remainder : Null<TilesetDef> = null;
			var remainingMap : Map<Int,Int> = new Map();
			if( remaining.length>0 ) {
				var units = buildUnits(old,remaining,groupsBySource.get(uid),true);
				var packed = pack(project,grid,units,sourceLookup);
				remainingMap = packed.mappings.get(uid);
				var tmpId = uniqueIdentifier(project,old.identifier+"_Remainder");
				var rel = OUTPUT_DIR+"/"+old.identifier+"_remaining_"+old.uid+".png";
				remainder = createGeneratedTileset(project,tmpId,rel,grid,packed.pixels.toPNG());
				generatedFiles.push(project.makeAbsoluteFilePath(rel,false));
			}

			migrations.push({
				old:old,
				selected:selected,
				selectedMap:packedDestination.mappings.get(uid),
				remainingMap:remainingMap,
				remainder:remainder,
			});
		}

		// Copy metadata before old definitions are removed.
		for(m in migrations) copyTilesetMetadata(m,destination);
		migrateReferences(project,migrations,destination);

		var removed = 0;
		for(m in migrations) {
			var oldIdentifier = m.old.identifier;
			project.disposeImage(m.old.relPath);
			project.defs.removeTilesetDef(m.old);
			removed++;
			if( m.remainder!=null ) m.remainder.identifier = oldIdentifier;
		}

		project.tidy();
		destination.buildPixelDataAndNotify();
		for(m in migrations)
			if( m.remainder!=null ) m.remainder.buildPixelDataAndNotify();

		return {
			destinationUid:destination.uid,
			destinationIdentifier:destination.identifier,
			movedTileCount:movedCount,
			removedTilesetCount:removed,
			generatedFiles:generatedFiles,
		};
	}
}
