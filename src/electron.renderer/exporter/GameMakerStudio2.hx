package exporter;

import ldtk.Json;

typedef RoomJson = {
	var isDnd: Bool;
	var volume: Float;
	var views: Array<Dynamic>;
	var layers: Array<Dynamic>;

	var inheritLayers: Bool;
	var inheritCode: Bool;
	var inheritCreationOrder: Bool;
	var creationCodeFile: String;

	var instanceCreationOrder: Array<Dynamic>;
	var sequenceId: Null<Dynamic>; // ??
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
	var parent: {
		var name:String;
		var path: String;
	}

	var resourceVersion: String;
	var name: String;
	var tags: Array<Dynamic>;
	var resourceType: String; // GMRoom
}

class GameMakerStudio2 extends Exporter {
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

			var json : RoomJson = {
				name: l.identifier,
				resourceType: "GMRoom",
				resourceVersion: "1.0",
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
				tags: [],
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

			// Save room JSON
			var jsonStr = dn.JsonPretty.stringify(json, Full);
			addOuputFile(fp.full, haxe.io.Bytes.ofString(jsonStr));
		}

		// var fp = outputPath.clone();
		// fp.fileName = projectPath.fileName;
		// fp.extension = "yy";
		// addOuputFile(fp.full, haxe.io.Bytes.ofString(json));
	}
}
