package nw;

@:enum abstract ClipboardType(String) {
	var Text = "text";
	var Png = "png";
	var Jpeg = "jpeg";
	var Html = "html";
	var Rtf = "rtf";
}

extern class Clipboard {

	function set( data : String, ?type : ClipboardType, ?raw : Bool ) : Void;
	function get( ?type : ClipboardType, ?raw : Bool ) : String;
	function readAvailableTypes() : Array<ClipboardType>;
	function clear() : Void;

	static function get() : Clipboard;

}