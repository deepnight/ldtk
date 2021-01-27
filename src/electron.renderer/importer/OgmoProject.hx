package importer;

import dn.M;

class OgmoProject {
	public var log : dn.Log;
	var fp : dn.FilePath;

	public function new(ogmoProjectPath:String) {
		fp = dn.FilePath.fromFile(ogmoProjectPath);
		log = new dn.Log();
		log.fileOp("Importing Ogmo project: "+fp.full);
	}

	public function load() : Null<data.Project> {
		// Read file
		var raw = JsTools.readFileString(fp.full);
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

		log.general("Successfully parsed project: "+json.name);

		// Init ogmo data cache
		var ogmoLayerJsons : Map<Int, OgmoLayerDef> = new Map();
		var ldtkLayerDefs : Map<String, data.def.LayerDef> = new Map(); // ogmo "name" as index
		var ldtkTilesets : Map<String, data.def.TilesetDef> = new Map(); // ogmo "label" as index

		// Prepare base project
		log.general('Preparing project...');
		var out = fp.clone();
		out.extension = Const.FILE_EXTENSION;
		var p = data.Project.createEmpty(out.full);
		p.worldLayout = LinearHorizontal;

		#if !debug
		try {
		#end
			// Project settings
			log.general('Reading project settings...');
			p.bgColor = convertColor(json.backgroundColor);
			p.defaultLevelBgColor = p.bgColor;
			p.defaultGridSize = readGrid(json.layerGridDefaultSize);



			// Tilesets **************************************************************
			log.general("Reading tileset defs...");
			log.indentMore();
			for(tilesetJson in json.tilesets) {
				log.general("Found tileset "+tilesetJson.label+" ("+tilesetJson.path+")");
				log.indentMore();
				var td = p.defs.createTilesetDef();
				ldtkTilesets.set(tilesetJson.label, td);
				td.identifier = data.Project.cleanupIdentifier(tilesetJson.label,true);
				td.tileGridSize = readGrid({ x:tilesetJson.tileWidth, y:tilesetJson.tileHeight });
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
				ed.identifier = data.Project.cleanupIdentifier(entityJson.name, true);
				ed.color = convertColor(entityJson.color);
				ed.width = entityJson.size.x;
				ed.height = entityJson.size.y;
				ed.pivotX = M.round( (entityJson.origin.x / entityJson.size.x) / 0.5 ) * 0.5;
				ed.pivotY = M.round( (entityJson.origin.y / entityJson.size.y) / 0.5 ) * 0.5;

				// Entity fields
				for(valJson in entityJson.values) {
					log.general("Found value "+valJson.name+" ("+valJson.definition+")");
					log.indentMore();

					// Convert type
					var type : data.DataTypes.FieldType = switch valJson.definition {
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
							enumDef.identifier = data.Project.cleanupIdentifier(entityJson.name+"_"+valJson.name, true);
							for(ev in valJson.choices)
								enumDef.addValue(ev);
							F_Enum(enumDef.uid);

						case _:
							log.error('Unsupported entity value type ${valJson.definition} in ${entityJson.name}');
							null;
					}

					// Create field def
					if( type!=null ) {
						var fd = ed.createFieldDef(p, type, valJson.name, false);

						fd.editorDisplayMode = switch valJson.display {
							case 0 : Hidden;
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
						var layer = p.defs.createLayerDef(IntGrid, data.Project.cleanupIdentifier(layerJson.name, true));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize);
						layer.intGridValues = [];
						var ignoreFirst = true;
						for(k in Reflect.fields(layerJson.legend)) {
							if( ignoreFirst ) {
								ignoreFirst = false;
								continue;
							}
							layer.addIntGridValue(
								convertColor( Reflect.field(layerJson.legend,k) ),
								data.Project.cleanupIdentifier(k,false)
							);
						}

					// Entity layer def
					case "entity":
						var layer = p.defs.createLayerDef(Entities, data.Project.cleanupIdentifier(layerJson.name, true));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize);

					// Tile layer def
					case "tile":
						var layer = p.defs.createLayerDef(Tiles, data.Project.cleanupIdentifier(layerJson.name, true));
						ldtkLayerDefs.set(layerJson.name, layer);
						layer.gridSize = readGrid(layerJson.gridSize);
						if( layerJson.defaultTileset!=null ) {
							var td = p.defs.getTilesetDef( data.Project.cleanupIdentifier(layerJson.defaultTileset, true) );
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
			var allFiles = JsTools.findFilesRec(fp.directory, "json");
			log.indentMore();
			for(fp in allFiles) {
				log.general("Found "+fp.full);
				log.indentMore();

				// Read level file
				var raw = try JsTools.readFileString(fp.full)
					catch(e:Dynamic) {
						log.error("Could not open level file: "+fp.full);
						continue;
					}

				// Parse level JSON
				var levelJson : OgmoLevelJson = try haxe.Json.parse(raw)
					catch(e:Dynamic) {
						log.error("Could not parse level JSON: "+fp.fileWithExt);
						continue;
					}

				// Create base level
				var level = p.createLevel();
				level.identifier = data.Project.cleanupIdentifier(fp.fileName,true);
				level.pxWid = levelJson.width;
				level.pxHei = levelJson.height;
				// TODO add level offset to layers
				p.tidy();

				// Layer instances
				log.general("Filling layers...");
				for(layer in levelJson.layers) {
					log.indentMore();
					log.debug(layer.name);
					var ld = ldtkLayerDefs.get(layer.name);
					if( ld==null ) {
						log.error('Layer "${layer.name}" from level ${fp.full} does not match any layer definition');
						continue;
					}
					var li = level.getLayerInstance(ld);
					li.pxOffsetX = levelJson.offsetX + layer.offsetX;
					li.pxOffsetY = levelJson.offsetY + layer.offsetY;
					switch ld.type {

						// IntGrid instance
						case IntGrid:
							var valueMap = new Map();
							var idx = 0;
							for(v in ld.getAllIntGridValues())
								valueMap.set(v.identifier, idx++);

							if( layer.grid!=null ) {
								iterateArray1D( layer.grid, li.cWid, (cx,cy,v)->{
									if( valueMap.exists(v) )
										li.setIntGrid( cx, cy, valueMap.get(v) );
								});
							}
							else if( layer.grid2D!=null ) {
								iterateArray2D(layer.grid2D, (cx,cy,v)->{
									if( valueMap.exists(v) )
										li.setIntGrid( cx, cy, valueMap.get(v) );
								});
							}


						case Entities:



						case Tiles:
							var defaultTdUid = ld.tilesetDefUid;
							var td = ldtkTilesets.get(layer.tileset);
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
							if( layer.tileFlags!=null )
								iterateArray1D(layer.tileFlags, li.cWid, (cx,cy,v)->{
									if( M.hasBit(v,0) )
										rotations++;
									flipBits.set( li.coordId(cx,cy), convertTransformFlagToFlipBits(v) );
								});
							else if( layer.tileFlags2D!=null )
								iterateArray2D(layer.tileFlags2D, (cx,cy,v)->{
									if( M.hasBit(v,0) )
										rotations++;
									flipBits.set( li.coordId(cx,cy), convertTransformFlagToFlipBits(v) );
								});

							// Tiles
							if( layer.data!=null ) {
								iterateArray1D( layer.data, li.cWid, (cx,cy,v)->{
									if( v>=0 )
										li.addGridTile(cx,cy, v, _getFlipBit(cx,cy));
								});
							}
							else if( layer.data2D!=null ) {
								iterateArray2D( layer.data2D, (cx,cy,v)->{
									if( v>=0 )
										li.addGridTile(cx,cy, v, _getFlipBit(cx,cy));
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
			p.removeLevel( p.levels[0] ); // remove default 1st level

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

	function readGrid(v:XY) : Int {
		if( v.y!=v.x )
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
			trace(v+"=>"+f);
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

	var entities: Array<Dynamic>;

	var grid: Array<String>;
	var grid2D: Array<Array<String>>;

	var tileset: String;
	var data: Array<Int>;
	var data2D: Array<Array<Int>>;
	var tileFlags: Array<Int>;
	var tileFlags2D: Array<Array<Int>>;
}