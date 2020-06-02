import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTED_VALUES : Map<LayerDef, Dynamic> = new Map();

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayerContent;

	var jPalette(get,never) : J; inline function get_jPalette() return client.jPalette;

	var running = false;
	var lastMouse : Null<MouseCoords>;
	var button = 0;

	private function new() {
		super(Client.ME);
		updatePalette();
	}

	function selectValue(v:T) {
		SELECTED_VALUES.set(curLayer.def, v);
			// M.iclamp(v, 0, curLayer.def.intGridValues.length-1)
	}
	function getSelectedValue() : T {
		return SELECTED_VALUES.exists(curLayer.def)
			? SELECTED_VALUES.get(curLayer.def)
			: getDefaultValue();
	}
	function getDefaultValue() : T {
		return null;
	}

	public function updatePalette() {
		jPalette.empty();
	}

	public function isRunning() return running;

	inline function isAdding() return running && button==0;
	inline function isRemoving() return running && button==1;

	public function startUsing(m:MouseCoords, buttonId:Int) {
		running = true;
		button = buttonId;
		lastMouse = m;
		useAt(m);
	}

	public function onMouseMove(m:MouseCoords) {
		if( isRunning() )
			useAt(m);
		lastMouse = m;
	}

	function useAt(m:MouseCoords) {}

	public function stopUsing(m:MouseCoords) {
		if( isRunning() )
			useAt(m);
		running = false;
	}
}