package importer;

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
		var json : OgmoJson = try haxe.Json.parse(raw)
			catch(e:Dynamic) {
				log.error("Could not parse JSON");
				return null;
			}

		log.general("Successfully parsed project: "+json.name);

		// Init ogmo data cache
		var ogmoLayers : Map<Int, OgmoLayerDef> = new Map();

		// Prepare base project
		log.general('Preparing project...');
		var out = fp.clone();
		out.extension = Const.FILE_EXTENSION;
		var p = data.Project.createEmpty(out.full);
		p.worldLayout = LinearHorizontal;

		try {
			// Project settings
			log.general('Reading project settings...');
			p.bgColor = convertColor(json.backgroundColor);
			p.defaultLevelBgColor = p.bgColor;
			p.defaultGridSize = readGrid(json.layerGridDefaultSize);

			// Tilesets
			log.general("Reading tileset defs...");
			log.indentMore();
			for(tilesetJson in json.tilesets) {
				log.general("Found tileset "+tilesetJson.label+" ("+tilesetJson.path+")");
				log.indentMore();
				var td = p.defs.createTilesetDef();
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

			// Layers
			log.general('Reading layer defs...');
			json.layers.reverse();
			log.indentMore();
			for(layerJson in json.layers) {
				log.general('Found layer ${layerJson.name} (${layerJson.definition})');
				log.indentMore();
				ogmoLayers.set(layerJson.exportID, layerJson);

				switch layerJson.definition {
					// IntGrid layer def
					case "grid":
						var layer = p.defs.createLayerDef(IntGrid, data.Project.cleanupIdentifier(layerJson.name, true));
						layer.gridSize = readGrid(layerJson.gridSize);
						layer.intGridValues = [];
						for(k in Reflect.fields(layerJson.legend)) {
							var idx = Std.parseInt(k)-1;
							if( idx<0 )
								continue;

							layer.intGridValues[idx] = {
								identifier: layer.identifier+"_"+k,
								color: convertColor( Reflect.field(layerJson.legend,k) ),
							}
						}

					// Entity layer def
					case "entity":
						var layer = p.defs.createLayerDef(Entities, data.Project.cleanupIdentifier(layerJson.name, true));
						layer.gridSize = readGrid(layerJson.gridSize);

					// Tile layer def
					case "tile":
						var layer = p.defs.createLayerDef(Tiles, data.Project.cleanupIdentifier(layerJson.name, true));
						layer.gridSize = readGrid(layerJson.gridSize);
						if( layerJson.defaultTileset!=null ) {
							log.debug("TODO tileset");
						}

					case _:
						log.error('Unsupported layer type ${layerJson.definition}');
				}
				log.indentLess();
			}
			log.clearIndent();

			log.general("Done.");
			return p;
		}
		catch(e:Dynamic) {
			log.error("Exception: "+e);
			return null;
		}
	}

	function readGrid(v:XY) : Int {
		if( v.y!=v.x )
			throw "Unsupported different grid height value";
		else
			return v.x;
	}

	function convertColor(rgba:String, keepAlpha=false) : Int {
		var c = Std.parseInt( "0x"+rgba.substr(1,6) );
		if( keepAlpha )
			C.addAlphaF( c, Std.parseInt("0x"+rgba.substr(7))/255 );
		return c;
	}
}


typedef XY = {
	var x : Int;
	var y : Int;
}


typedef OgmoJson = {
	var name: String;
	var levelPaths: Array<String>;
	var backgroundColor: String;
	var layerGridDefaultSize : XY;

	var layers: Array<OgmoLayerDef>;
	var tilesets: Array<OgmoTilesetDef>;
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
	// "tilesets": [
		// {"label": "myIncaFront", "path": "atlas/Inca_extended_front_by_Kronbits.png", "image": "data:image/png;base64,
		// "tileWidth": 16, "tileHeight": 16, "tileSeparationX": 0, "tileSeparationY": 0, "tileMarginX": 0, "tileMarginY": 0},
}