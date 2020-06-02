import dn.Bresenham;

class Tool extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayer;

	var running = false;
	var lastMouse : Null<MouseCoords>;

	private function new() {
		super(Client.ME);
	}

	public function isRunning() return running;

	public function startUsing(m:MouseCoords) {
		running = true;
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