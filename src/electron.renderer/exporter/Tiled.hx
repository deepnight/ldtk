package exporter;

import haxe.Json;
import ldtk.Json;


// TMX documentation: https://doc.mapeditor.org/en/stable/reference/tmx-map-format/
class Tiled extends Exporter {
	static var TILED_VERSION = "1.4.2";
	static var MAP_VERSION = "1.4";

	var tiledGridSize = 16;

	public function new() {
		super();
	}

	override function convert() {
		super.convert();

		setOutputPath( projectPath.directory + "/" + p.getRelExternalFilesDir() + "/tiled", true );

		var curWorld = p.worlds[0]; // HACK support multi-worlds for Tiled

		// Prepare world object
		var world = {
			maps: [],
			type: "world",
		};

		/**
			Determine a unique "grid size" value because Tiled doesn't support yet different
			grid sizes in the same map file.
		**/
		tiledGridSize = p.defaultGridSize;
		if( p.defs.layers.length>0 )
			tiledGridSize = dn.Lib.findMostFrequentValueInArray( p.defs.layers.map( (ld)->ld.gridSize ) );
		log.general("Guessed gridSize: "+tiledGridSize+"px");
		for(ld in p.defs.layers)
			if( ld.gridSize!=tiledGridSize )
				log.error("Layer "+ld.identifier+" uses a specific grid size ("+ld.gridSize+"px). Tiled only supports a single grid size for all layers (here, "+tiledGridSize+"px).");

		// Export each level to a separate TMX file
		var i = 1;
		for(l in curWorld.levels) {
			var bytes = exportLevel(l);

			var fp = outputPath.clone();
			fp.fileName = ( curWorld.levels.length>1 ? '${dn.Lib.leadingZeros(i,Const.LEVEL_FILE_LEADER_ZEROS)}_' : '' ) + l.identifier;
			fp.extension = "tmx";
			addOuputFile(fp.full, bytes);

			world.maps.push({
				fileName: fp.fileWithExt,
				x:l.worldX,
				y:l.worldY,
			});
			i++;
		}

		// Create "world" JSON file
		log.emptyEntry();
		log.fileOp("Creating world JSON...");
		var json = dn.data.JsonPretty.stringify(world);
		var fp = outputPath.clone();
		fp.fileName = projectPath.fileName;
		fp.extension = "world";
		addOuputFile(fp.full, haxe.io.Bytes.ofString(json));
	}


	function exportLevel(level:data.Level) : haxe.io.Bytes {
		log.emptyEntry();
		log.add("level", "Exporting level "+level.identifier+"...");

		var xml = Xml.createDocument();
		var layerId = 1;
		var objectId = 1;
		var gid = 1;

		var mapWidth = M.ceil( level.pxWid/tiledGridSize );
		var mapHeight = M.ceil( level.pxHei/tiledGridSize );

		/**
			MAP

			<map version="1.2" tiledversion="1.3.1" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="200" height="200" tilewidth="8" tileheight="8" infinite="0" backgroundcolor="#171c39" nextlayerid="35" nextobjectid="272">
		**/
		var map = Xml.createElement("map");
		xml.addChild(map);
		map.set("version", MAP_VERSION);
		map.set("tiledversion", TILED_VERSION);
		map.set("orientation", "orthogonal");
		map.set("renderorder", "right-down");
		map.set("compressionlevel", "0");
		map.set("width", ""+mapWidth);
		map.set("height", ""+mapHeight);
		map.set("tilewidth", ""+tiledGridSize);
		map.set("tileheight", ""+tiledGridSize);
		map.set("infinite", "0");
		map.set("backgroundcolor", C.intToHex(level.getBgColor()) );

		/**
			TILESETS

			<tileset firstgid="1" name="cavesofgallet_tiles" tilewidth="8" tileheight="8" tilecount="384" columns="12">
				<image source="cavesofgallet_tiles.png" width="96" height="256"/>
			</tileset>
		**/
		var tilesetGids = new Map();
		for( td in p.defs.tilesets ) {
			if( !td.hasAtlasPointer() ) {
				log.warning("Skipped undefined tileset: "+td.identifier);
				continue;
			}

			if( td.isUsingEmbedAtlas() ) {
				log.warning("Skipped embedded tileset: "+td.identifier);
				continue;
			}

			log.add("tileset", 'Adding tileset ${td.identifier}...');
			if( td.padding!=0 )
				log.error('Tileset ${td.identifier} has padding, which isn\'t supported by Tiled.');

			var count = M.ceil(td.pxWid/td.tileGridSize) * M.ceil(td.pxHei/td.tileGridSize);
			var tileset = Xml.createElement("tileset");
			map.addChild(tileset);
			tileset.set("firstgid",""+gid);
			tileset.set("name", td.identifier);
			tileset.set("tilewidth", ""+td.tileGridSize);
			tileset.set("tileheight", ""+td.tileGridSize);
			tileset.set("tilecount", "" + count);
			tileset.set("columns", "" + M.ceil(td.pxWid/td.tileGridSize) );
			tileset.set("objectalignment", "topleft" );
			tileset.set("margin", "0" );
			tileset.set("spacing", ""+td.spacing );

			var relPath = remapRelativePath(td.relPath);
			log.add("tileset", '  Adding image: ${relPath}');
			var fp = dn.FilePath.fromFile(td.relPath);
			if( fp.extension!=null && ( fp.extension.toLowerCase()=="aseprite" || fp.extension.toLowerCase()=="ase" ) )
				log.error('Aseprite format (from tileset ${td.identifier}) is not supported in Tiled.');
			var image = Xml.createElement("image");
			tileset.addChild(image);
			image.set("source", relPath);
			image.set("width", ""+td.pxWid);
			image.set("height", ""+td.pxHei);

			if ( td.hasAnyTileCustomData() ) {
				for ( tileId in 0...count ) {
					var tileData = td.getTileCustomData(tileId);
					if ( tileData != null ) {
						var tile = Xml.createElement("tile");
						tile.set("id", "" + tileId);
						var properties = Xml.createElement("properties");
						var dataFields = Json.parse(tileData);
						for ( key in Reflect.fields(dataFields) ) {
							var value = Reflect.field(dataFields, key);
							if ( value is Array ) continue;
							var property = Xml.createElement("property");
							property.set("name", key);
							switch ( Type.typeof(value) ) {
								case TBool:
									property.set("type", "bool");
								case TInt:
									property.set("type", "int");
								case TFloat:
									property.set("type", "float");
								case TObject:
									property = null;
								case _:
							}
							if ( property != null ) {
								property.set("value", ""+value);
								properties.addChild(property);
							}
						}
						if ( properties.firstChild() != null ) {
							log.add("tileset", '  Adding custom properties for tile: ${tileId}');
							tile.addChild(properties);
							tileset.addChild(tile);
						}
					}
				}
			}

			tilesetGids.set(td.uid, gid);
			gid+=count;
		}

		/**
			Create IntGrid fake tilesets (basically, just colored squares)
		**/
		for(ld in p.defs.layers) {
			if( ld.type==IntGrid ) {
				var count = ld.countIntGridValues();

				// Create image data
				var bd = new hxd.BitmapData( count*ld.gridSize, ld.gridSize );
				var i = 0;
				for(v in ld.getAllIntGridValues())  {
					bd.fill( i*ld.gridSize, 0, ld.gridSize, ld.gridSize, C.addAlphaF(v.color) );
					i++;
				}

				// Save PNG
				var fp = outputPath.clone();
				fp.fileName = ld.identifier+".intgrid";
				fp.extension = "png";
				addOuputFile(fp.full, bd.toPNG());

				// Build tileset XML
				var tileset = Xml.createElement("tileset");
				map.addChild(tileset);
				tileset.set("firstgid",""+gid);
				tileset.set("name", ld.identifier);
				tileset.set("tilewidth", ""+ld.gridSize);
				tileset.set("tileheight", ""+ld.gridSize);
				tileset.set("tilecount", "" + count);
				tileset.set("columns", "" + count);
				tileset.set("objectalignment", "topleft" );

				// Build image XML
				var image = Xml.createElement("image");
				tileset.addChild(image);
				image.set("source", fp.fileWithExt);
				image.set("width", ""+bd.width);
				image.set("height", ""+bd.height);

				tilesetGids.set(ld.uid, gid);
				gid+=count;
			}
		}


		/** Create a Tiled "tileId" from a LDtk "tileId" **/
		function _makeTiledTileId(tilesetUid:Int, tileId:Int, flips=0) : UInt {
			if( flips==0 )
				return tilesetGids.get(tilesetUid) + tileId;
			else {
				var gid : UInt = tilesetGids.get(tilesetUid) + tileId;

				if( M.hasBit(flips,0) )
					gid = M.setUnsignedBit(gid, 31);

				if( M.hasBit(flips,1) )
					gid = M.setUnsignedBit(gid, 30);

				return gid;
			}
		}


		/**
			LAYERS

			<layer id="32" name="collisions" width="200" height="200" opacity="0.79">
				<properties>
					<property name="advColl" type="bool" value="true"/>
				</properties>
				<data encoding="csv">...</data>
			</layer>
		**/
		function _createLayer(type:String, li:data.inst.LayerInstance, nameSuffix="") {
			var layer = Xml.createElement(type);
			map.addChild(layer);
			layer.set("id", Std.string(layerId++));
			layer.set("name", li.def.identifier + nameSuffix);
			switch type {
				case "layer":
					layer.set("width",""+li.cWid);
					layer.set("height",""+li.cHei);
					layer.set("opacity",""+li.def.displayOpacity);

				case "objectgroup":
			}
			return layer;
		}

		function _createTileObject(tilesetDefUid:Int, tileId:Int, x:Int, y:Int, flips=0) : Xml {
			var o = Xml.createElement("object");
			o.set("id", Std.string(objectId++));
			o.set("gid", ""+_makeTiledTileId(tilesetDefUid, tileId, flips));
			o.set("x", ""+x);
			o.set("y", ""+y);
			o.set("width", ""+p.defs.getTilesetDef(tilesetDefUid).tileGridSize);
			o.set("height", ""+p.defs.getTilesetDef(tilesetDefUid).tileGridSize);
			return o;
		}

		var allInst = level.layerInstances.copy();
		allInst.reverse();
		for(li in allInst) {
			if( li.def.gridSize!=tiledGridSize ) {
				log.error("In level "+level.identifier+": discarded layer "+li.def.identifier+" (incompatible grid size)");
				continue;
			}
			var ld = p.defs.layers.filter( (ld)->ld.uid==li.layerDefUid )[0];
			log.add("layer", "Layer "+ld.identifier+"...");


			switch ld.type {
				case IntGrid:
					// Prepare CSV
					var csv = new Csv(li.cWid, li.cHei);
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid)
						if( li.hasIntGrid(cx,cy) )
							csv.set( cx, cy, _makeTiledTileId(li.def.uid, li.getIntGrid(cx,cy)-1, 0) );

					// Build layer XML
					log.add("layer", "  Exporting IntGrid values");
					var layer = _createLayer("layer", li, li.def.isAutoLayer() ? "_values" : null);
					var data = Xml.createElement("data");
					layer.addChild(data);
					data.set("encoding","csv");
					data.addChild( Xml.createPCData( csv.getString() ) );

				case Entities:
					function _createProperty(props:Xml, name:String, type:Null<String>, val:Dynamic) {
						var prop = Xml.createElement("property");
						props.addChild(prop);
						prop.set("name", name);
						if( type!=null )
							prop.set("type", type);
						prop.set("value", Std.string(val));
						return prop;
					}

					var layer = _createLayer("objectgroup", li);
					for(e in li.entityInstances) {
						var object = Xml.createElement("object");
						layer.addChild(object);
						var x = e.x;
						var y = e.y;
						if( e.def.pivotX!=0 || e.def.pivotY!=0 ) {
							// log.warning('${e.def.identifier} entity uses a non-"topleft" pivot point which Tiled does not support.');
							x -= M.round(e.def.pivotX*e.def.width);
							y -= M.round(e.def.pivotY*e.def.height);
						}

						object.set("name",e.def.identifier);
						object.set("type",e.def.identifier);
						object.set("x",""+x);
						object.set("y",""+y);
						object.set("width",""+e.def.width);
						object.set("height",""+e.def.height);

						var props = Xml.createElement("properties");
						object.addChild(props);

						_createProperty(props, "__anchorX", "int", ""+e.x);
						_createProperty(props, "__anchorY", "int", ""+e.y);
						_createProperty(props, "__cx", "int", ""+e.getCx(ld));
						_createProperty(props, "__cy", "int", ""+e.getCy(ld));

						// Entity fields
						for(fi in e.fieldInstances)
						for( i in 0...fi.getArrayLength() ) {
							// Type
							var type = switch fi.def.type {
								case F_Int: "int";
								case F_Float: "float";
								case F_String: null;
								case F_Text: null;
								case F_Bool: "bool";
								case F_Color: "color";
								case F_Enum(enumDefUid): null;
								case F_Point: null;
								case F_Path: "file";
								case F_Tile: "tile";
								case F_EntityRef: null; // TODO entity refs in Tiled?
							}
							// Value
							var v : Dynamic = switch fi.def.type {
								case F_Int: fi.getInt(i);
								case F_Float: fi.getFloat(i);
								case F_Path: fi.getFilePath(i);
								case F_String, F_Text: fi.getString(i);
								case F_Bool: fi.getBool(i);
								case F_Color:
									var c = fi.getColorAsHexStr(i);
									c = c.substr(1);
									"#ff"+c;
								case F_Enum(enumDefUid): fi.getEnumValue(i);
								case F_Point: fi.getPointStr(i);
								case F_EntityRef: fi.getEntityRefIid(i);
								case F_Tile: fi.getTileRectStr(i);
							}
							_createProperty(props, fi.def.identifier + (fi.getArrayLength()<=1 ? "" : "_"+i), type, v);
						}
					}

				case Tiles:
					// Detect stacked tiles
					var maxStack = 0;
					for( coordId in li.gridTiles.keys() )
						maxStack = M.imax(maxStack, li.gridTiles.get(coordId).length);

					// One Tiled-layer per "stack-layer"
					for( layerIdx in 0...maxStack ) {
						// Build CSV
						var csv = new Csv(li.cWid, li.cHei);
						log.add("layer", "    Building CSV "+(layerIdx+1));
						for( coordId in li.gridTiles.keys() ) {
							var stack = li.gridTiles.get(coordId);
							if( layerIdx < stack.length ) {
								csv.setCoordId( coordId, _makeTiledTileId(li.getTilesetUid(), stack[layerIdx].tileId, stack[layerIdx].flips) );
							}
						}

						// Create layer XML
						var layer = _createLayer("layer", li, maxStack>1 ? "_"+(layerIdx+1) : "");
						var data = Xml.createElement("data");
						layer.addChild(data);
						data.set("encoding","csv");
						data.addChild( Xml.createPCData( csv.getString() ) );
					}


				case AutoLayer:
			}


			// Auto-layer tiles
			if( ld.tilesetDefUid!=null ) {
				log.add("layer", "  Exporting Auto-Layer tiles");
				var td = li.getTilesetDef();
				var csvLayers : Array<Csv> = [];
				var hasIncompatibleTiles = false;

				ld.iterateActiveRulesInDisplayOrder( li, (r)->{
					if( !li.autoTilesCache.exists(r.uid) )
						return;

					var ruleResults = li.autoTilesCache.get(r.uid);
					for( coordId in ruleResults.keys() ) {
						for(t in ruleResults.get(coordId)) {
							// Create csv layers if this coordId already has a tile
							var layerIdx = 0;
							var cx = Std.int( t.x / li.def.gridSize );
							var cy = Std.int( t.y / li.def.gridSize );
							if( !hasIncompatibleTiles && ( t.x%li.def.gridSize!=0 || t.y%li.def.gridSize!=0 ) )
								hasIncompatibleTiles = true;
							while( layerIdx < csvLayers.length && csvLayers[layerIdx].has(cx,cy) )
								layerIdx++;
							if( csvLayers[layerIdx] == null )
								csvLayers[layerIdx] = new Csv(li.cWid, li.cHei);

							// Add tile
							csvLayers[layerIdx].set(
								cx, cy,
								_makeTiledTileId( td.uid, t.tid, t.flips )
							);
						}
					}
				});

				// Warn for freely positioned tiles
				if( hasIncompatibleTiles )
					log.error("Layer "+li.def.identifier+" in level "+level.identifier+" contains tiles that are not aligned with the grid, which isn't supported in Tiled. They will appear shifted in the TMX file.");

				// Create one XML layer per CSV
				var layerIdx = 0;
				for(csv in csvLayers) {
					var layer = _createLayer("layer", li, csvLayers.length>1 ? "_"+(layerIdx+1) : "");
					log.add("layer", "    Building CSV "+(layerIdx+1));
					var data = Xml.createElement("data");
					layer.addChild(data);
					data.set("encoding","csv");
					data.addChild( Xml.createPCData( csv.getString() ) );
					layerIdx++;
				}
			}
		}

		map.set("nextlayerid", ""+layerId);
		map.set("nextobjectid", ""+objectId);

		return haxe.io.Bytes.ofString( xml.toString() );
	}
}


private class Csv {
	var wid: Int;
	var hei: Int;
	var data: Map<Int, UInt>;

	public function new(w,h) {
		wid = w;
		hei = h;
		data = new Map();
	}

	public inline function set(cx:Int, cy:Int, v:UInt) {
		if( cx>=0 && cy>=0 && cx<wid && cy<hei )
			setCoordId(cx+cy*wid, v);
	}

	public inline function setCoordId(coordId:Int, v:UInt) {
		if( coordId>=0 && coordId<wid*hei )
			data.set(coordId, v);
	}

	public inline function get(cx,cy) : UInt {
		return data.exists( cx+cy*wid ) ? data.get(cx+cy*wid) : 0;
	}

	public inline function has(cx,cy) : Bool {
		return data.exists( cx+cy*wid );
	}

	public inline function getCoordId(coordId:Int) : UInt {
		return data.exists( coordId ) ? data.get( coordId ) : 0;
	}

	public function getString() {
		var out : Array<String> = [];
		for(cy in 0...hei)
		for(cx in 0...wid)
			out.push( Std.string( get(cx,cy) ) );
		return out.join(",");
	}
}
