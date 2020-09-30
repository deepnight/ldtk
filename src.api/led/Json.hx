package led;

typedef LedFloat = String; // HACK

typedef ProjectJson = {
	var name: String;
	var jsonVersion: String;
	var defaultPivotX: LedFloat;
	var defaultPivotY: LedFloat;
	var defaultGridSize: Int;
	var bgColor: String;
	var nextUid: Int;
	var minifyJson: Bool;
	var defs: Dynamic; // JSON
	var levels: Array<Dynamic>; // JSON
}