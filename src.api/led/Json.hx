package led;

/** Root of the Json file **bold** **/
typedef ProjectJson = {
	/** File format version **/
	var jsonVersion: String;

	/** Default X pivot (0 to 1) for new entities **/
	var defaultPivotX: Float;

	/** Default Y pivot (0 to 1) for new entities **/
	var defaultPivotY: Float;

	/** Default grid size for new layers **/
	var defaultGridSize: Int;

	/** Project BG color **/
	var bgColor: String;

	@:hide
	var nextUid: Int;

	/** If TRUE, the Json is partially minified (no indentation, nor line breaks) **/
	var minifyJson: Bool;

	var defs: Dynamic; // JSON
	var levels: Array<Dynamic>; // JSON
}