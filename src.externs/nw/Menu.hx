package nw;

@:enum abstract MenuType(String) {
	var Menubar = "menubar";
	var ContextMenu = "contextmenu";
}

extern class Menu {

	public function new( ?options : { ?label : String, ?type : MenuType } ) : Void;
	public function append( m : MenuItem ) : Void;
	public function popup( x : Int, y : Int ) : Void;

}