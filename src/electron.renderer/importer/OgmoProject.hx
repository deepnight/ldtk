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

		// Prepare empty project
		log.general('Preparing project...');
		var out = fp.clone();
		out.extension = Const.FILE_EXTENSION;
		var p = data.Project.createEmpty(out.full);

		try {
			// Project settings
			log.general('Reading project settings...');
			p.bgColor = convertColor(json.backgroundColor);
			p.defaultLevelBgColor = p.bgColor;
			p.defaultGridSize = readGrid(json.layerGridDefaultSize);

			// Layers
			log.general('Reading layers...');
			for(layerJson in json.layers) {
				log.general('Found layer ${layerJson.name} (${layerJson.definition})');
				switch layerJson.definition {
					case "grid":
						var layer = p.defs.createLayerDef(IntGrid, data.Project.cleanupIdentifier(layerJson.name, true));
						for(k in Reflect.fields(layerJson.legend)) {
							trace(k);
							trace(Reflect.field(layerJson.legend,k));
						}

					case _: log.error('Unsupported layer type ${layerJson.definition}');
				}
			}

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

	var layers: Array<{
		var definition: String;
		var name: String;
		var gridSize: XY;
		var legend: Map<Int,String>;
	}>;
}