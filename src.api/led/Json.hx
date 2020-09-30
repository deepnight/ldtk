package led;

typedef ProjectJson = {
	var name: String;
	var jsonVersion: String;
	var defaultPivotX: Float;
	var defaultPivotY: Float;
	var defaultGridSize: Int;
	var bgColor: String;
	var nextUid: Int;
	var minifyJson: Bool;
	var defs: Dynamic; // JSON
	var levels: Array<Dynamic>; // JSON
}