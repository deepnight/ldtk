package exporter;

import ldtk.Json;

// Tiled GMS export: https://doc.mapeditor.org/en/latest/manual/export-yy/

typedef GMResource = {
	var resourceVersion: String;
	var resourceType: String;
	var name: String;
	var tags: Array<Dynamic>; // TODO
}

typedef GMPath = {
	var name: String;
	var path: String;
}

typedef GMRoom = {
	> GMResource,
	var isDnd: Bool;
	var volume: Float;

	var views: Array<{
		var inherit: Bool;
		var visible: Bool;
		var xview: Int;
		var yview: Int;
		var wview: Int;
		var hview: Int;

		var xport: Int;
		var yport: Int;
		var wport: Int;
		var hport: Int;

		var hborder: Int;
		var vborder: Int;

		var hspeed: Int;
		var vspeed: Int;

		var objectId: Null<Dynamic>; // TODO
	}>;
	var layers: Array<GMRLayer>;

	var inheritLayers: Bool;
	var inheritCode: Bool;
	var inheritCreationOrder: Bool;
	var creationCodeFile: String;

	var instanceCreationOrder: Array<Dynamic>;
	var sequenceId: Null<Dynamic>; // TODO
	var roomSettings: {
		var inheritRoomSettings: Bool;
		var persistent: Bool;
		var Width: Int;
		var Height: Int;
	};
	var viewSettings: {
		var inheritViewSettings: Bool;
		var enableViews: Bool;
		var clearViewBackground: Bool;
		var clearDisplayBuffer: Bool;
	};
	var physicsSettings: {
		var inheritPhysicsSettings: Bool;
		var PhysicsWorld: Bool;
		var PhysicsWorldGravityX: Float;
		var PhysicsWorldGravityY: Float;
		var PhysicsWorldPixToMetres: Float;
	};
	var parent: GMPath;
}


typedef GMRLayer = {
	> GMResource,
	var visible: Bool;
	var depth: Int;
	var userdefinedDepth: Bool;
	var inheritLayerDepth: Bool;
	var inheritLayerSettings: Bool;
	var hierarchyFrozen: Bool;
	var effectEnabled: Bool;
	var effectType: Null<Dynamic>; // TODO
	var gridX: Int;
	var gridY: Int;
	var layers: Array<Dynamic>; // TODO
	var properties: Array<Dynamic>; // TODO
	var ?x: Int;
	var ?y: Int;

	// ???
	var ?instances: Array<GMRInstance>;

	// Tile layer
	var ?tilesetId: GMPath;
	var ?tiles: {
		var SerialiseWidth: Int;
		var SerialiseHeight: Int;
		var TileSerialiseData: Array<Float>;
	}

	// Background layer
	var ?spriteId: Null<Dynamic>; // TODO
	var ?colour: Int;
	var ?htiled: Bool;
	var ?vtiled: Bool;
	var ?stretch: Bool;
	var ?hspeed: Float;
	var ?vspeed: Float;
	var ?animationFPS: Float;
	var ?animationSpeedType: Int;
	var ?userdefinedAnimFPS: Bool;
}

typedef GMRInstance = {
	>GMResource,
	var isDnd: Bool;
	var objectId: GMPath;
}

typedef GMRTileset = {
	>GMResource,
}



class GameMakerStudio2 extends Exporter {
	static var RESOURCE_VERSION = "1.0";

	public function new() {
		super();
	}

	override function convert() {
		super.convert();

		setOutputPath( projectPath.directory + "/" + p.getRelExternalFilesDir() + "/gms2", true );


		// Resources references
		var resourcesPaths : Map<String, GMPath> = new Map();
		function _storeRsc(name:String, absPath:String) {
			var relPath = dn.FilePath.fromFile(absPath);
			relPath.makeRelativeTo( outputPath.full );
			resourcesPaths.set(name, {
				name: name,
				path: relPath.full,
			});
		}
		function _getRsc(name:String) {
			if( !resourcesPaths.exists(name) )
				throw 'Unknown resource $name';
			return resourcesPaths.get(name);
		}


		// Init tilesets JSON
		for(td in p.defs.tilesets) {
			var tilesetJson : GMRTileset = {
				name: td.identifier,
				tags: [],
				resourceType: "GMRTileset",
				resourceVersion: RESOURCE_VERSION,
			}

			var fp = outputPath.clone();
			fp.fileName = td.identifier;
			fp.extension = "yy";
			addOuputFile(
				fp.full,
				haxe.io.Bytes.ofString( dn.data.JsonPretty.stringify(tilesetJson) )
			);

			_storeRsc(td.identifier, fp.full);
		}


		// Levels
		for(w in p.worlds)
		for(l in w.levels) {
			// Init room JSON
			var roomJson : GMRoom = {
				name: l.identifier,
				resourceType: "GMRoom",
				resourceVersion: RESOURCE_VERSION,
				tags: [],

				parent: {
					name: "",
					path: "",
				}, // ??

				isDnd: false,
				inheritCode: false,
				inheritLayers: false,
				inheritCreationOrder: false,
				instanceCreationOrder: [],
				volume: 1,
				creationCodeFile: "",
				sequenceId: null,

				layers: [],
				views: [],

				physicsSettings: {
					inheritPhysicsSettings: false,
					PhysicsWorld: false,
					PhysicsWorldGravityX: 0,
					PhysicsWorldGravityY: 10,
					PhysicsWorldPixToMetres: 0.1,
				},
				roomSettings: {
					Width: l.pxWid,
					Height: l.pxHei,
					persistent: false,
					inheritRoomSettings: false,
				},
				viewSettings: {
					enableViews: false,
					inheritViewSettings: false,
					clearDisplayBuffer: true,
					clearViewBackground: false,
				},
			}


			// Layers
			var depth = 0;
			for(li in l.layerInstances) {
				// Base layer JSON
				var layerJson : GMRLayer = {
					resourceVersion: RESOURCE_VERSION,
					resourceType: switch li.def.type {
						case IntGrid: "?";
						case Entities: "GMRInstanceLayer";
						case Tiles: "GMRTileLayer";
						case AutoLayer: "GMRTileLayer";
					},
					name: li.def.identifier,
					tags: [],

					properties: [],
					layers: [],
					gridX: li.def.gridSize,
					gridY: li.def.gridSize,

					effectType: null,
					effectEnabled: true,

					userdefinedDepth: false,
					inheritLayerDepth: false,
					hierarchyFrozen: false,
					inheritLayerSettings: false,
					depth: depth*100,
					visible: true,
				}

				// Specific layer data depending on type
				switch li.def.type {
					case IntGrid:

					case Entities:
						// Instance layer
						layerJson.instances = [];

					case Tiles:
						// Tile layers
						var tilesData = [];
						for(cy in 0...li.cHei)
						for(cx in 0...li.cWid) {
							var ts = li.getGridTileStack(cx,cy);
							if( ts.length==0 )
								tilesData.push(2147483648);
							else
								tilesData.push(ts[0].tileId);
						}
						layerJson.tiles = {
							SerialiseWidth: li.cWid,
							SerialiseHeight: li.cHei,
							TileSerialiseData: tilesData,
						}
						layerJson.x = li.pxTotalOffsetX;
						layerJson.y = li.pxTotalOffsetY;
						layerJson.tilesetId = _getRsc( li.getTilesetDef().identifier );

					case AutoLayer:
				}
				roomJson.layers.push(layerJson);
				depth++;
			}

			// Save room JSON
			var fp = outputPath.clone();
			fp.fileName = l.identifier;
			fp.extension = "yy";
			addOuputFile(
				fp.full,
				haxe.io.Bytes.ofString( dn.data.JsonPretty.stringify(roomJson) )
			);
		}
	}

}
