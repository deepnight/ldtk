package nw;

extern class Shell {

	public static function openExternal(uri:String) : Void;
	public static function openItem(file_path:String) : Void;
	public static function showItemInFolder(file_path:String) : Void;
}