import dn.Bresenham;

class Tool extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayer;

	var jToolBar(get,never) : J; inline function get_jToolBar() return client.jToolBar;

	var running = false;
	var lastMouse : Null<MouseCoords>;
	var button = 0;

	private function new() {
		super(Client.ME);
		updateToolBar();
	}

	public function updateToolBar() {
		jToolBar.empty();
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