package nw;

@:enum abstract MenuItemType(String) {
	var Normal = "normal";
	var Checkbox = "checkbox";
	var Separator = "separator";
}

typedef MenuItemOptions = { label : String, ?icon : String, ?type : MenuItemType, ?submenu : Menu };

extern class MenuItem {

	public var checked : Bool;
	public var enabled : Bool;

	public function new( options : MenuItemOptions ) : Void;
	public dynamic function click() : Void;
}