package nw;

extern class Window {

	public var x : Int;
	public var y : Int;
	public var width : Int;
	public var height : Int;
	public var zoomLevel : Float;

	public var window : js.html.Window;

	public var menu : Menu;
	public var title : String;

	public function showDevTools() : Void;

	public function moveTo( x : Int, y : Int ) : Void;
	public function moveBy( dx : Int, dy : Int ) : Void;
	public function resizeTo( w : Int, h : Int ) : Void;
	public function resizeBy( dw : Int, dh : Int ) : Void;

	public function maximize() : Void;
	public function minimize() : Void;
	public function restore() : Void;
	public function enterFullscreen() : Void;
	public function leaveFullscreen() : Void;
	public function on( event : String, callb : Void -> Void ) : Void;

	public function show( b : Bool ) : Void;

	public function close( ?force : Bool ) : Void;

	public static function get() : Window;
	public static function open( url : String, ?params : {?new_instance:Bool,?inject_js_start:String,?inject_js_end:String,?id:String}, ?callb:Window->Void ) : Void;

}