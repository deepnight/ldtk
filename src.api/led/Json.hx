package led;

typedef ProjectJson = {
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