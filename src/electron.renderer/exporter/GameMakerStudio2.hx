package exporter;

import ldtk.Json;

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
	var ?tiles: Dynamic; // TODO

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



class GameMakerStudio2 extends Exporter {
	static var RESOURCE_VERSION = "1.0";

	public function new() {
		super();
	}

	override function convert() {
		super.convert();

		setOutputPath( projectPath.directory + "/" + p.getRelExternalFilesDir() + "/gms2", true );

		for(w in p.worlds)
		for(l in w.levels) {
			var fp = outputPath.clone();
			fp.fileName = l.identifier;
			fp.extension = "yy";

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

			var depth = 0;
			for(li in l.layerInstances) {
				var layerJson : GMRLayer = {
					resourceVersion: RESOURCE_VERSION,
					resourceType: switch li.def.type {
						case IntGrid: "?";
						case Entities: "?";
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
				switch li.def.type {
					case IntGrid:
					case Entities:
					case Tiles:
						layerJson.tiles = [];
						layerJson.x = li.pxTotalOffsetX;
						layerJson.y = li.pxTotalOffsetY;
						layerJson.tilesetId = {
							name: "TODO",
							path: "TODO",
						}

					case AutoLayer:
				}
				roomJson.layers.push(layerJson);
				depth++;
			}

			// Save room JSON
			var jsonStr = dn.JsonPretty.stringify(roomJson, Full);
			addOuputFile(fp.full, haxe.io.Bytes.ofString(jsonStr));
		}

		// var fp = outputPath.clone();
		// fp.fileName = projectPath.fileName;
		// fp.extension = "yy";
		// addOuputFile(fp.full, haxe.io.Bytes.ofString(json));
	}
}
