class Tool extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayer;

	var running = false;

	private function new() {
		super(Client.ME);
	}

	public function isRunning() return running;

	public function startUsing() {
		running = true;
		use();
	}

	public function use() {}

	function getMouse() return Client.ME.getMouse();

	public function stopUsing() {
		use();
		running = false;
	}
}