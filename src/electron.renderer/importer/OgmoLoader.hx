package importer;

import dn.M;

class OgmoLoader {
	static var MIN_VERSION = "3.3";

	public var log : dn.Log;
	var fp : dn.FilePath;

	public function new(ogmoProjectPath:String) {
		fp = dn.FilePath.fromFile(ogmoProjectPath);
		log = new dn.Log();
		log.fileOp("Importing Ogmo project: "+fp.full);
	}

	public function load() : Null<data.Project> {
		// Read file
		var raw = NT.readFileString(fp.full);
		if( raw==null ) {
			log.error("Could not open file");
			return null;
		}

		// Parse JSON
		var json : OgmoProjectJson = try haxe.Json.parse(raw)
			catch(e:Dynamic) {
				log.error("Could not parse JSON");
				return null;
			}

		// Version check
		if( json.ogmoVersion==null || Version.lower(json.ogmoVersion, MIN_VERSION, true) ) {
			log.error("This Ogmo project should be first saved using Ogmo "+MIN_VERSION+" or later. LDtk doesn't support older file versions.");
			return null;
		}

		log.general("Successfully parsed project: "+json.name);

		// Init ogmo data cache
		var ogmoLayerJsons : Map<Int, OgmoLayerDef> = new Map();
		var ldtkLayerDefs : Map<String, data.def.LayerDef> = new Map(); // ogmo "name" as index
		var ldtkTilesets : Map<String, data.def.TilesetDef> = new Map(); // ogmo "label" as index
		var ldtkEntities : Map<String, data.def.EntityDef> = new Map(); // ogmo "name" as index
		var ldtkIntGridIds : Map<Int, Map<String,String>> = new Map(); // Map<LayerDefUid, Map<ogmoIntGridName>>

		// Prepare base project
		log.general('Preparing project...');
		var out = fp.clone();
		out.extension = Const.FILE_EXTENSION;
		var p = data.Project.createEmpty(out.full);
		p.identifierStyle = Free;
		var world = p.worlds[0];
		world.worldLayout = Free;

		#if !debug
		try {
		#end
			// Project settings
			log.general('Reading project settings...');
			p.bgColor = convertColor(json.backgroundColor);
			p.defaultLevelBgColor = p.bgColor;
			p.defaultGridSize = readGrid(json.layerGridDefaultSize, 16);



			// Tilesets **************************************************************
			log.general("Reading tileset defs...");
			log.indentMore();
			for(tilesetJson in json.tilesets) {
				log.general("Found tileset "+tilesetJson.label+" ("+tilesetJson.path+")");
				log.indentMore();
				var td = p.defs.createTilesetDef();
				ldtkTilesets.set(tilesetJson.label, td);
				td.identifier = data.Project.cleanupIdentifier(tilesetJson.label, p.identifierStyle);
				td.tileGridSize = readGrid({ x:tilesetJson.tileWidth, y:tilesetJson.tileHeight }, 16);
				td.spacing = tilesetJson.tileSeparationX;
				td.padding = tilesetJson.tileMarginX;
				var path = fp.directory+"/"+tilesetJson.path;
				var res = td.importAtlasImage(tilesetJson.path);
				switch res {
					case Ok:
						log.fileOp("Image imported succesfully.");

					case FileNotFound:
						log.error("File not found: "+path);

					case LoadingFailed(err):
						log.error("Image loading failed: "+err);

					case _:
				}
				log.indentLess();
			}
			log.clearIndent();



			// Entity defs **************************************************************
			log.general("Reading entity defs...");
			log.indentMore();
			for(entityJson in json.entities) {
				log.general("Found entity "+entityJson.name);
				log.indentMore();

				// Create base entity
				var ed = p.defs.createEntityDef();
				ldtkEntities.set(entityJson.name, ed);
				ed.identifier = data.Project.cleanupIdentifier(entityJson.name, p.identifierStyle);
				ed.color = convertColor(entityJson.color);
				ed.width = entityJson.size.x;
				ed.height = entityJson.size.y;
				ed.pivotX = M.round( (entityJson.origin.x / entityJson.size.x) / 0.5 ) * 0.5;
				ed.pivotY = M.round( (entityJson.origin.y / entityJson.size.y) / 0.5 ) * 0.5;
				ed.maxCount = entityJson.limit<=0 ? 0 : entityJson.limit;
				ed.resizableX = entityJson.resizeableX;
				ed.resizableY = entityJson.resizeableY;
				ed.tags.fromArray( entityJson.tags );

				// Entity fields
				for(valJson in entityJson.values) {
					log.general("Found value "+valJson.name+" ("+valJson.definition+")");
					log.indentMore();

					// Convert type
					var type : ldtk.Json.FieldType = switch valJson.definition {
						case "Integer": F_Int;
						case "Float": F_Float;
						case "Boolean": F_Bool;
						case "Color": F_Color;
						case "String": F_String;
						case "Text": F_Text;
						case "Filepath": F_Path;

						case "Enum":
							// Create enum def
							var enumDef = p.defs.createEnumDef();
							enumDef.identifier = data.Project.cleanupIdentifier(entityJson.name+"_"+valJson.name, p.identifierStyle);
							for(ev in valJson.choices)
								if( enumDef.addValue(ev)==null )
									log.error("Enum value is invalid or already used in entity "+entityJson.name+"."+valJson.name);
							F_Enum(enumDef.uid);

						case _:
							log.error('Unsupported entity value type ${valJson.definition} in ${entityJson.name}');
							null;
					}

					// Create field def
					if( type!=null ) {
						var fd = ed.createFieldDef(p, type, valJson.name, false);

						fd.editorDisplayMode = switch valJson.display {
							case 0 : NameAndValue; // fix buggy displayMode
							case 1 : ValueOnly;
							case _ : NameAndValue;
						}

						switch type {
							case F_Int, F_Float:
								fd.setDefault( Std.string(valJson.defaults) );
								if( valJson.bounded ) {
									fd.min = valJson.min;
									fd.max = valJson.max;
								}

							case F_String, F_Text:
								fd.setDefault( Std.string(valJson.defaults) );

							case F_Bool:
								fd.setDefault( Std.string(valJson.defaults) );

							case F_Color:
								fd.setDefault( C.intToHex(convertColor(valJson.defaults)) );

							case F_Enum(enumDefUid):
								fd.canBeNull = true;

							case F_Point:

							case F_Path:
								fd.setAcceptFileTypes( valJson.extensions.join(" ") );

							case F_EntityRef:

							case F_Tile:
						}

					}

					log.indentLess();
				}

				// Entity nodes
				if( entityJson.hasNodes ) {
					var fd = ed.createFieldDef(p, F_Point, "ogmoNodes", true);
				}

				log.indentLess();
			}
			log.clearIndent();



			// Layers **************************************************************
			log.general('Reading layer defs...');
			json.layers.reverse();
			log.indentMore();
			for(layerJson in json.layers) {
				log.general('Found layer ${layerJson.name} (${layerJson.definition})');
				log.indentMore();
				ogmoLayerJsons.set(layerJson.exportID, layerJson);

				switch layerJson.definition {
					// IntGrid layer def
					case "grid":
						var layer = p.defs.createLayerDef(IntGrid, data.Project.cleanupIdentifier(layerJson.name, p.identifierStyle));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize, 16);
						layer.intGridValues = [];
						ldtkIntGridIds.set(layer.uid, new Map());
						var ignoreFirst = true;
						var numReg = ~/^[0-9]+$/gi;
						for(k in Reflect.fields(layerJson.legend)) {
							if( ignoreFirst ) {
								ldtkIntGridIds.get(layer.uid).set(k, null);
								ignoreFirst = false;
								continue;
							}
							var baseId = numReg.match(k) ? "v"+k : k;
							var id = data.Project.cleanupIdentifier(baseId, Free);
							var inc = 2;
							while( !layer.isIntGridValueIdentifierValid(id) )
								id = data.Project.cleanupIdentifier(baseId+"_"+(inc++), Free);
							ldtkIntGridIds.get(layer.uid).set(k, id);
							layer.addIntGridValue( convertColor( Reflect.field(layerJson.legend,k) ), id );
						}

					// Entity layer def
					case "entity":
						var layer = p.defs.createLayerDef(Entities, data.Project.cleanupIdentifier(layerJson.name, p.identifierStyle));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize, 16);
						layer.requiredTags.fromArray( layerJson.requiredTags );
						layer.excludedTags.fromArray( layerJson.excludedTags );

					// Tile layer def
					case "tile":
						var layer = p.defs.createLayerDef(Tiles, data.Project.cleanupIdentifier(layerJson.name, p.identifierStyle));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize, 16);
						if( layerJson.defaultTileset!=null ) {
							var td = p.defs.getTilesetDef( data.Project.cleanupIdentifier(layerJson.defaultTileset, p.identifierStyle) );
							if( td!=null )
								layer.tilesetDefUid = td.uid;
							else
								log.error("Unknown tileset "+layerJson.defaultTileset);
						}

					case _:
						log.error('Unsupported layer type ${layerJson.definition}');
				}
				log.indentLess();
			}
			log.clearIndent();



			// Levels **************************************************************
			log.general('Reading levels...');
			var allFiles : Array<dn.FilePath> = [];
			for(dir in json.levelPaths) {
				var path = dn.FilePath.cleanUp( fp.directory+"/"+dir, false );
				log.general("Exploring dir: "+path);
				allFiles = allFiles.concat( JsTools.findFilesRec(path, "json") );
			}
			var dones : Map<String,Bool> = new Map();
			log.indentMore();
			var levelFiles = new Map();
			for(fp in allFiles) {
				if( dones.exists(fp.full) )
					continue;

				log.general("Found "+fp.full);
				log.indentMore();
				dones.set(fp.full,true);

				// Read level file
				var raw = try NT.readFileString(fp.full)
					catch(e:Dynamic) {
						log.error("Could not open file: "+fp.full);
						continue;
					}

				// Parse level JSON
				var levelJson : OgmoLevelJson = try haxe.Json.parse(raw)
					catch(e:Dynamic) {
						log.warning("Could not parse supposed level JSON: "+fp.fileWithExt);
						continue;
					}

				// Create base level
				var level = world.createLevel();
				levelFiles.set(fp.full, {
					l: level,
					fp: fp,
				});
				level.identifier = data.Project.cleanupIdentifier(fp.fileName, p.identifierStyle);
				level.useAutoIdentifier = false;
				level.pxWid = levelJson.width;
				level.pxHei = levelJson.height;
				// TODO add level offset to layers
				p.tidy();



				// Layer instances **************************************************************

				log.general("Filling layers...");
				for(layerJson in levelJson.layers) {
					log.indentMore();
					log.debug(layerJson.name);
					var ld = ldtkLayerDefs.get(layerJson.name);
					if( ld==null ) {
						log.error('Layer "${layerJson.name}" from level ${fp.full} does not match any layer definition');
						continue;
					}
					var li = level.getLayerInstance(ld);
					li.pxOffsetX = levelJson.offsetX + layerJson.offsetX;
					li.pxOffsetY = levelJson.offsetY + layerJson.offsetY;
					switch ld.type {

						// IntGrid instance
						case IntGrid:
							// var valueMap = new Map();
							// var idx = 0;
							// for(v in ld.getAllIntGridValues())
							// 	valueMap.set(v.identifier, idx++);

							if( layerJson.grid!=null ) {
								iterateArray1D( layerJson.grid, li.cWid, (cx,cy,v)->{
									if( !ldtkIntGridIds.get(li.layerDefUid).exists(v) )
										log.error("Unknown IntGrid value "+v+" in "+li.def.identifier);
									li.setIntGrid(
										cx, cy,
										li.def.getIntGridIndexFromIdentifier(ldtkIntGridIds.get(li.layerDefUid).get(v)),
										false
									);
								});
							}
							else if( layerJson.grid2D!=null ) {
								iterateArray2D(layerJson.grid2D, (cx,cy,v)->{
									if( !ldtkIntGridIds.get(li.layerDefUid).exists(v) )
										log.error("Unknown IntGrid value "+v+" in "+li.def.identifier);
									li.setIntGrid(
										cx, cy,
										li.def.getIntGridIndexFromIdentifier(ldtkIntGridIds.get(li.layerDefUid).get(v)),
										false
									);
								});
							}


						case Entities:
							for(entJson in layerJson.entities) {
								var ed = ldtkEntities.get(entJson.name);
								if( ed==null ) {
									log.error('Unknown entity ${entJson.name} in level ${fp.fileWithExt}');
									continue;
								}

								// Base entity instance
								var ei = li.createEntityInstance(ed);
								ei.x = entJson.x;
								ei.y = entJson.y;
								ei.customWidth = ed.resizableX && entJson.width!=null && entJson.width!=ed.width ? entJson.width : null;
								ei.customHeight = ed.resizableY && entJson.height!=null && entJson.height!=ed.height ? entJson.height: null;

								// Fields values
								if( entJson.values!=null )
									for(k in Reflect.fields(entJson.values)) {
										var fd = ed.getFieldDef( data.Project.cleanupIdentifier(k, Free) );
										if( fd==null ) {
											log.error('Unknown value $k in entity ${entJson.name} in level ${fp.fileWithExt}');
											continue;
										}
										var fi = ei.getFieldInstance(fd,true);
										var rawValue = Std.string( Reflect.field(entJson.values, k) );
										switch fd.type {
											case F_Int, F_Float, F_String, F_Text, F_Bool:
												fi.parseValue(0, rawValue);

											case F_Color:
												fi.parseValue(0, C.intToHex(convertColor(rawValue)) );

											case F_Enum(enumDefUid):
												var ev = data.Project.cleanupIdentifier(rawValue, p.identifierStyle);
												fi.parseValue(0, ev);

											case F_Point:
											case F_Path:
												if( rawValue!="" && rawValue!=null )
													fi.parseValue(0, rawValue.split(":")[1]);

											case F_Tile:
											case F_EntityRef:
										}

										if( fi.isEqualToDefault(0) )
											fi.parseValue(0, null);
									}
							}


						case Tiles:
							var defaultTdUid = ld.tilesetDefUid;
							var td = ldtkTilesets.get(layerJson.tileset);
							log.debug("uses tileset: "+td.identifier);
							if( td.uid!=ld.tilesetDefUid ) {
								log.debug("not default!");
								@:privateAccess li.overrideTilesetUid = td.uid;
							}
							// Transform flags
							var rotations = 0;
							var flipBits = new Map();
							inline function _getFlipBit(cx,cy) {
								return flipBits.exists( li.coordId(cx,cy) ) ? flipBits.get( li.coordId(cx,cy) ) : 0;
							}
							if( layerJson.tileFlags!=null )
								iterateArray1D(layerJson.tileFlags, li.cWid, (cx,cy,v)->{
									if( M.hasBit(v,0) )
										rotations++;
									flipBits.set( li.coordId(cx,cy), convertTransformFlagToFlipBits(v) );
								});
							else if( layerJson.tileFlags2D!=null )
								iterateArray2D(layerJson.tileFlags2D, (cx,cy,v)->{
									if( M.hasBit(v,0) )
										rotations++;
									flipBits.set( li.coordId(cx,cy), convertTransformFlagToFlipBits(v) );
								});

							// Tiles
							if( layerJson.data!=null ) {
								iterateArray1D( layerJson.data, li.cWid, (cx,cy,v)->{
									if( v>=0 )
										li.addGridTile(cx,cy, v, _getFlipBit(cx,cy), false, false);
								});
							}
							else if( layerJson.data2D!=null ) {
								iterateArray2D( layerJson.data2D, (cx,cy,v)->{
									if( v>=0 )
										li.addGridTile(cx,cy, v, _getFlipBit(cx,cy), false, false);
								});
							}

							if( rotations>0 )
								log.error("Found "+rotations+" unsupported tile rotation(s) in layer "+li.def.identifier);
						case AutoLayer:
					}

					log.indentLess();
				}

				log.indentLess();
			}
			log.clearIndent();
			world.removeLevel( world.levels[0] ); // remove default 1st level


			// Organize levels in 2D world space
			var x = 0;
			var lines = [];
			var lineIndexes = new Map();
			for(l in levelFiles) {
				if( !lineIndexes.exists(l.fp.directory) ) {
					lineIndexes.set(l.fp.directory, lines.length);
					lines.push([]);
				}
				lines[ lineIndexes.get(l.fp.directory) ].push(l.l);
				l.l.worldX = x;
				x += l.l.pxWid + 16;
			}

			var gapX = 16;
			var gapY = 64;
			var y = 0;
			for(line in lines) {
				var lineHei = 0;
				var x = 0;
				for(l in line) {
					l.worldX = x;
					l.worldY = y;
					lineHei = M.imax(lineHei, l.pxHei);
					x += l.pxWid + gapX;
				}
				y += lineHei + gapY;
			}


			log.general("Done.");
			return p;

		#if !debug
		}
		catch(e:Dynamic) {
			log.error("Exception: "+e);
			return null;
		}
		#end
	}



	function iterateArray1D<T>(arr:Array<T>, lineWid:Int, cb:(cx:Int, cy:Int, v:T)->Void)  {
		var cx = 0;
		var cy = 0;
		for(v in arr) {
			cb(cx,cy, v);
			cx++;
			if( cx>=lineWid ) {
				cx = 0;
				cy++;
			}
		}
	}

	function iterateArray2D<T>(arr:Array<Array<T>>, cb:(cx:Int, cy:Int, v:T)->Void) {
		for(cy in 0...arr.length)
		for(cx in 0...arr[cy].length)
			cb(cx,cy, arr[cy][cx]);
	}

	function readGrid(v:XY, defaultIfMissing:Int) : Int {
		if( v==null || !Reflect.hasField(v,"x") )
			return defaultIfMissing;
		else if( v.y!=v.x )
			throw "Unsupported different grid height value";
		else
			return v.x;
	}

	function convertTransformFlagToFlipBits(v:Int) {
		if( M.hasBit(v,1) || M.hasBit(v,2) ) {
			var f = 0;
			if( M.hasBit(v,1) ) // Y
				f = M.setBit(f, 1);
			if( M.hasBit(v,2) ) // X
				f = M.setBit(f, 0);
			return f;
		}
		else
			return 0;
	}

	function convertColor(rgba:String, keepAlpha=false) : Int {
		var c = Std.parseInt( "0x"+rgba.substr(1,6) );
		if( keepAlpha )
			C.addAlphaF( c, Std.parseInt("0x"+rgba.substr(7))/255 );
		return c;
	}
}



// OGMO JSON **************************************************************

typedef XY = {
	var x : Int;
	var y : Int;
}


typedef OgmoProjectJson = {
	var name: String;
	var ogmoVersion: String;
	var levelPaths: Array<String>;
	var backgroundColor: String;
	var layerGridDefaultSize : XY;

	var layers: Array<OgmoLayerDef>;
	var tilesets: Array<OgmoTilesetDef>;
	var entities: Array<OgmoEntityDef>;
}

typedef OgmoLayerDef = {
	var exportID: Int;
	var definition: String;
	var name: String;
	var gridSize: XY;
	var arrayMode: Int;
	var legend: Map<Int,String>;
	var defaultTileset: Null<String>;
	var requiredTags: Array<String>;
	var excludedTags: Array<String>;
}

typedef OgmoTilesetDef = {
	var label: String;
	var path: String;
	var image: String;
	var tileWidth: Int;
	var tileHeight: Int;
	var tileSeparationX: Int;
	var tileSeparationY: Int;
	var tileMarginX: Int;
	var tileMarginY: Int;
}

typedef OgmoEntityDef = {
	var name: String;
	var limit: Int;
	var size: XY;
	var origin: XY;
	var originAnchored: Bool;
	var color: String;
	var hasNodes: Bool;
	var values: Array<OgmoEntityValueDef>;
	var resizeableX: Bool;
	var resizeableY: Bool;
	var tags: Array<String>;
}

typedef OgmoEntityValueDef = {
	var name: String;
	var definition: String;
	var display: Int;
	var defaults: Dynamic;

	var bounded: Bool;
	var min: Float;
	var max: Float;

	var choices: Array<String>;

	var extensions: Array<String>;
}

typedef OgmoLevelJson = {
	var width: Int;
	var height: Int;
	var offsetX: Int;
	var offsetY: Int;
	var layers: Array<OgmoLayerInst>;
}

typedef OgmoLayerInst = {
	var name: String;
	var _eid: Int;
	var offsetX: Int;
	var offsetY: Int;
	var arrayMode: Int;
	var exportMode: Int;

	var entities: Array<OgmoEntityInst>;

	var grid: Array<String>;
	var grid2D: Array<Array<String>>;

	var tileset: String;
	var data: Array<Int>;
	var data2D: Array<Array<Int>>;
	var tileFlags: Array<Int>;
	var tileFlags2D: Array<Array<Int>>;
}

typedef OgmoEntityInst = {
	var name: String;
	var x: Int;
	var y: Int;
	var values: Dynamic;
	var ?width: Int;
	var ?height: Int;
}